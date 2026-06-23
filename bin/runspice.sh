#!/bin/zsh
script_name=$(basename "$0")
start_time=$(date +%s)

# Run the command and time it
#output=$("$@" 2>&1)
"$@"

end_time=$(date +%s)
elapsed_time=$(( end_time - start_time ))
# Extract the program name from the command
program_name=$(basename "$1")

# Format the message
message="The command '$program_name' completed in $elapsed_time seconds."

# Send the iMessage (or just echo for now)
echo "$script_name: $message"

# Print the output of the command to the terminal
#echo "$output"
