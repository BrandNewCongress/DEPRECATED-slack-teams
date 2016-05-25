require 'google/apis/script_v1'
require 'googleauth'
require 'googleauth/stores/file_token_store'

require 'fileutils'

OOB_URI = 'urn:ietf:wg:oauth:2.0:oob'
APPLICATION_NAME = 'BNC Apps Script Form Copy Update '
CLIENT_SECRETS_PATH = 'google_apps_client_secret.json'
CREDENTIALS_PATH = File.join(Dir.home, '.credentials',
                             "google-apps-ruby-script-creds.yaml")
SCOPES = ['https://www.googleapis.com/auth/drive', 
          'https://www.googleapis.com/auth/forms',
          'https://www.googleapis.com/auth/urlshortener']

class FormCopyAppsScriptExecutor

  def copy_form(city, spreadsheet_key)
    # Initialize the API
    service = Google::Apis::ScriptV1::ScriptService.new
    service.client_options.application_name = APPLICATION_NAME
    service.authorization = authorize

    # Create an execution request object.
    request = Google::Apis::ScriptV1::ExecutionRequest.new(
      function: 'copyFormAndUpdateProperties',
      parameters: [
        ENV['ORIGINAL_GOOGLE_FORM_ID'] || '',
        "#{city.capitalize} BNC Tour Volunteer To-Do List",
        "#{city.capitalize} BNC Tour Volunteer To-Do List",
        spreadsheet_key
      ],
      devMode: false
    )

    begin
      # Make the API request.
      resp = service.run_script(ENV['FORM_COPY_APPS_SCRIPT_ID'], request)

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
        # The Apps Script returns the ID of the new form
        short_url = resp.response['result']
        if short_url.empty?
          puts "No new form ID returned!"
        else
          puts "New Form ID: #{short_url}"
        end
        return short_url
      end
    rescue Exception => e
      # The API encountered a problem before the script started executing.
      puts "Error calling API: #{e}"
    end
  end

  private

  ##
  # Ensure valid credentials, either by restoring from the saved credentials
  # files or intitiating an OAuth2 authorization. If authorization is required,
  # the user's default browser will be launched to approve the request.
  #
  # @return [Google::Auth::UserRefreshCredentials] OAuth2 credentials
  def authorize
    FileUtils.mkdir_p(File.dirname(CREDENTIALS_PATH))

    client_id = Google::Auth::ClientId.from_file(CLIENT_SECRETS_PATH)
    token_store = Google::Auth::Stores::FileTokenStore.new(file: CREDENTIALS_PATH)
    authorizer = Google::Auth::UserAuthorizer.new(
      client_id, SCOPES, token_store)
    user_id = 'default'
    credentials = authorizer.get_credentials(user_id)
    if credentials.nil?
      url = authorizer.get_authorization_url(
        base_url: OOB_URI)
      puts "Open the following URL in the browser and enter the " +
           "resulting code after authorization"
      puts url
      code = ENV['GOOGLE_API_AUTH_CODE']
      credentials = authorizer.get_and_store_credentials_from_code(
        user_id: user_id, code: code, base_url: OOB_URI)
    end
    credentials
  end

end
