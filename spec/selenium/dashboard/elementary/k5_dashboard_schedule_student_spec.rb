# frozen_string_literal: true

#
# Copyright (C) 2021 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

require_relative '../../common'
require_relative '../pages/k5_dashboard_page'
require_relative '../../helpers/k5_common'
require_relative '../../grades/setup/gradebook_setup'

describe "student k5 dashboard schedule" do
  include_context "in-process server selenium tests"
  include K5PageObject
  include K5Common
  include GradebookSetup

  before :once do
    student_setup
  end

  before :each do
    user_session @student
    @now = Time.zone.now
  end

  context 'entry' do
    it 'navigates to planner when Schedule is clicked' do
      create_dated_assignment(@subject_course, 'Today Assignment', @now)

      get "/"

      select_schedule_tab
      wait_for_ajaximations

      expect(today_header).to be_displayed
    end
  end

  context 'navigation' do
    before :each do
      [
        ["Today assignment",@now],
        ["Previous Assignment", 7.days.ago(@now)],
        ["Future Assignment", 7.days.from_now(@now)]
      ].each do |assignment_info|
        create_dated_assignment(@subject_course, assignment_info[0], assignment_info[1])
      end
    end

    it 'starts the current week on the schedule' do

      get "/#schedule"
      wait_for_ajaximations

      expect(beginning_of_week_date).to include(beginning_weekday_calculation(@now))
      expect(end_of_week_date).to include(ending_weekday_calculation(@now))
    end

    it 'navigates to previous week with previous button' do

      get "/#schedule"

      click_previous_week_button
      wait_for_ajaximations

      expect(beginning_of_week_date).to include(beginning_weekday_calculation(1.week.ago(@now)))
      expect(end_of_week_date).to include(ending_weekday_calculation(1.week.ago(@now)))
    end

    it 'navigates to next week with the forward button' do

      get "/#schedule"

      click_next_week_button
      wait_for_ajaximations

      expect(beginning_of_week_date).to include(beginning_weekday_calculation(1.week.from_now(@now)))
      expect(end_of_week_date).to include(ending_weekday_calculation(1.week.from_now(@now)))
    end

    it 'navigates back to current week with today button' do

      get "/#schedule"

      click_previous_week_button
      wait_for_ajaximations
      expect(beginning_of_week_date).to include(beginning_weekday_calculation(1.week.ago(@now)))

      click_today_button
      wait_for_ajaximations

      expect(beginning_of_week_date).to include(beginning_weekday_calculation(@now))
      expect(end_of_week_date).to include(ending_weekday_calculation(@now))
    end
  end

  context 'missing items dropdown' do
    it 'finds no missing dropdown if there are no missing items' do
      assignment = create_dated_assignment(@subject_course, 'missing assignment', @now)
      assignment.submit_homework(@student, {submission_type: "online_text_entry", body: "Here it is"})

      get "/#schedule"

      expect(items_missing_exists?).to be_falsey
    end

    it 'finds the missing dropdown if there are missing items' do
      create_dated_assignment(@subject_course, 'missing assignment', 1.day.ago(@now))

      get "/#schedule"

      expect(items_missing_exists?).to be_truthy
    end

    it 'shows missing items and count if there are missing items' do
      create_dated_assignment(@subject_course, 'missing assignment1', 1.day.ago(@now))
      create_dated_assignment(@subject_course, 'missing assignment2', 1.day.ago(@now))


      get "/#schedule"

      expect(missing_data.text).to eq('Show 2 missing items')
    end

    it 'shows the list of missing assignments in dropdown' do
      skip('LS-2203 click_missing items is not working right all the time. unskip when fixed')
      assignment1 = create_dated_assignment(@subject_course, 'missing assignment1', 1.day.ago(@now))
      create_dated_assignment(@subject_course, 'missing assignment2', 1.day.ago(@now))

      get "/#schedule"
      wait_for_ajaximations

      click_missing_items
      wait_for_ajaximations

      assignments_list = missing_assignments

      expect(assignments_list.count).to eq(2)
      expect(assignments_list.first.text).to include('missing assignment1')
      expect(assignment_link(missing_assignments[0], @subject_course.id, assignment1.id)).to be_displayed
    end

    it 'clicking list twice hides missing assignments' do
      skip('LS-2203 click_missing items is not working right all the time. unskip when fixed')
      create_dated_assignment(@subject_course, 'missing assignment1', 1.day.ago(@now))

      get "/#schedule"
      wait_for_ajaximations

      click_missing_items

      assignments_list = missing_assignments

      expect(assignments_list.count).to eq(1)

      click_missing_items
      wait_for_ajaximations

      expect(missing_assignments_exist?).to be_falsey
    end
  end

  context 'course-scoped schedule tab included items' do
    it 'shows schedule info for course items' do
      create_dated_assignment(@subject_course, 'today assignment1', @now)

      get "/courses/#{@subject_course.id}#schedule"

      expect(today_header).to be_displayed
      expect(schedule_item.text).to include('today assignment1')
    end

    it 'shows course missing item in dropdown' do
      create_dated_assignment(@subject_course, 'yesterday assignment1', 1.day.ago(@now))

      get "/courses/#{@subject_course.id}#schedule"

      expect(items_missing_exists?).to be_truthy
    end
  end

  context 'course-scoped schedule tab excluded items' do
    before(:once) do
      course_with_student(
        active_all: true,
        user: @student,
        course_name: 'Social Studies'
      )
      create_dated_assignment(@course, 'assignment for other course', @now)
    end

    it 'does not show schedule info for non course item' do
      get "/courses/#{@subject_course.id}#schedule"

      expect(schedule_item_exists?).to be_falsey
    end

    it 'does not show non-course missing item in dropdown' do
      get "/courses/#{@subject_course.id}#schedule"

      expect(items_missing_exists?).to be_falsey
    end
  end

  context 'course color' do
    it 'shows the course color on the planner assignment listing' do
      new_color = '#07AB99'
      @subject_course.update!(course_color: new_color)
      create_dated_assignment(@subject_course, 'assignment for other course', @now)

      get "/#schedule"

      expect(hex_value_for_color(planner_assignment_header)).to eq(new_color)
    end
  end
end
