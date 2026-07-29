#-------------------------------------------------------------------------------------------#
# Redmine CMDB plugin: Configuration Management DataBase                                    #
# Copyright (C) 2025 Franz Apeltauer                                                        #
#                                                                                           #
# This program is free software: you can redistribute it and/or modify it under the terms   #
# of the GNU Affero General Public License as published by the Free Software Foundation,    #
# either version 3 of the License, or (at your option) any later version.                   #
#                                                                                           #
# This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; #
# without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. #
# See the GNU Affero General Public License for more details.                               #
#                                                                                           #
# You should have received a copy of the GNU Affero General Public License                  #
# along with this program.  If not, see <https://www.gnu.org/licenses/>.                    #
#-------------------------------------------------------------------------------------eohdr-#
# Purpose: Monkey patch extending Redmine's Issue model with CI associations.
#          Adds has_many relationships to enable linking configuration items to issues.

module HrzCmdb
  module Patches
    module IssuePatch
      # Called when module is included in Issue class.
      # Adds CI associations to Issue model using class_eval.
      # Parameter base: The Issue class that includes this module
      def self.included(base)
        base.class_eval do
          has_many :ci_issues, class_name: 'HrzcmCiIssue', foreign_key: 'issue_id', dependent: :destroy
          has_many :cis, through: :ci_issues, class_name: 'HrzcmCi'

          after_save :hrz_cmdb_log_linked_issue_assignee_change

          # Logs a CI audit entry when the assignee of an issue changes,
          # for every CI linked to this issue via an 'issue_ref' custom field.
          def hrz_cmdb_log_linked_issue_assignee_change
            return unless saved_change_to_attribute?(:assigned_to_id)

            linked_values = HrzcmCiCustomFieldValue
                              .joins(:field_def)
                              .where(value: id.to_s)
                              .where(hrzcm_ci_custom_field_defs: { field_type: 'issue_ref' })

            return if linked_values.empty?

            old_id, new_id = saved_change_to_attribute(:assigned_to_id)
            old_user = old_id.present? ? User.find_by(id: old_id) : nil
            new_user = new_id.present? ? User.find_by(id: new_id) : nil
            old_name = old_user ? "#{old_user.firstname} #{old_user.lastname}" : I18n.t('hrz_cmdb.custom_fields.issue_ref.unassigned', default: 'Unassigned')
            new_name = new_user ? "#{new_user.firstname} #{new_user.lastname}" : I18n.t('hrz_cmdb.custom_fields.issue_ref.unassigned', default: 'Unassigned')

            linked_values.each do |cf_value|
              ci = cf_value.ci
              next unless ci
              field_label = cf_value.field_def.b_name.presence || I18n.t('hrz_cmdb.custom_fields.types.issue_ref', default: 'Linked Issue')
              HrzcmCiAudit.log(ci, action: 'update',
                field: "#{field_label} - #{I18n.t('hrz_cmdb.custom_fields.issue_ref.assignee', default: 'Assignee')}",
                old_val: "##{id}: #{old_name}",
                new_val: "##{id}: #{new_name}")
            end
          end
        end
      end
    end
  end
end

# Apply the patch
unless Issue.included_modules.include?(HrzCmdb::Patches::IssuePatch)
  Issue.send(:include, HrzCmdb::Patches::IssuePatch)
end
