require 'google/apis/script_v1'
require 'dotenv'
Dotenv.load

class FormAddQuestionsScriptExecutor
  attr_accessor :client

  def add_questions_to_form(form_key)

    puts "Invoking script to add questions for Form with ID: #{form_key}"

    request = Google::Apis::ScriptV1::ExecutionRequest.new(
      function: 'addQuestionsToForm',
      parameters: [
        form_key || ENV['GOOGLE_FORM_ADD_QUESTIONS']
      ],
      devMode: false
    )

    begin
      resp = client.run_script(ENV['FORM_ADD_QUESTIONS_SCRIPT_ID'], request)

      if resp.error
        # The API executed, but the script returned an error.

        # Extract the first (and only) set of error details. The values of this
        # object are the script's 'errorMessage' and 'errorType', and an array of
        # stack trace elements.
        error = resp.error.details[0]

        puts "Script error message: #{error['errorMessage']}"

        if error['scriptStackTraceElements']
          # There may not be a stacktrace if the script didn't start executing.
          puts "Script error stacktrace:"
          error['scriptStackTraceElements'].each do |trace|
            puts "\t#{trace['function']}: #{trace['lineNumber']}"
          end
        end
      else
        # The Apps Script returns the ID of the form if it succeeded
        success = resp.response['result']
        if success
          puts "Added questions successfully"
        else
          puts "Failed to add questions"
        end
        return success
      end
    rescue Exception => e
      # The API encountered a problem before the script started executing.
      puts "Error calling Apps Script API: #{e}"
      return false
    end
  end
end
