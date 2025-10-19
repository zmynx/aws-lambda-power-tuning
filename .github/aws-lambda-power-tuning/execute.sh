name: AWS Lambda Power Tuning Script Runner
description: Runs a bash script with a JSON config (from path or inline), with optional overrides.
branding:
  icon: terminal
  color: blue

inputs:
  config_json_directory:
    description: Directory where the config JSON file is located.
    required: true
  config_json_name:
    description: Name of the config JSON file.
    required: true

runs:
  using: composite
  steps:

    - name: Check if config JSON exists
      shell: bash
      id: check_config
      working-directory: ${{ github.action_path }}
      env:
        CONFIG_JSON_PATH: ${{ inputs.config_json_directory }}/${{ inputs.config_json_name }}
      run: |
        if [ ! -f "${CONFIG_JSON_PATH}" ]; then
          echo "Config JSON file not found at $CONFIG_JSON_PATH"
          exit 1
        fi

    - name: AWS Lambda Power Tuning Script Execution
      id: analysis
      shell: bash
      working-directory: ${{ github.action_path }}
      env:
        CONFIG_JSON_PATH: ${{ inputs.config_json_directory }}/${{ inputs.config_json_name }}
      run: |
        ./execute.sh $CONFIG_JSON_PATH | tee output.log


    - name: Write Summary to GitHub Step Summary
      if: steps.analysis.outcome == 'success'
      shell: bash
      working-directory: ${{ github.action_path }}
      run: |
        # Extract the visualization URL from the output
        VISUALIZATION_URL=$(grep -o 'https://lambda-power-tuning.show/[^"]*' output.log)

        # Write formatted summary
        {
          echo '### ✅ AWS Lambda Power Tuning Summary'
          echo ''
          echo '**Execution Status:** `SUCCEEDED`'
          echo ''
          echo '**🔍 Output Details:**'
          echo '```json'
          cat output.log
          echo '```'
          echo ''
          echo '**📊 Visualization:** [🔗 Click here to view the visualization]('$VISUALIZATION_URL')'
          echo ''
          echo '---'
        } >> $GITHUB_STEP_SUMMARY

    - name: Write Error to GitHub Step Summary
      if: steps.analysis.outcome != 'success'
      shell: bash
      working-directory: ${{ github.action_path }}
      run: |
        # Write error message to step summary
        {
          echo '### ❌ AWS Lambda Power Tuning Failed'
          echo ''
          echo 'An error occurred while running the AWS Lambda Power Tuning script.'
          echo ''
          echo 'Please check the logs for more details.'
          echo ''
          echo '---'
        } >> $GITHUB_STEP_SUMMARY
