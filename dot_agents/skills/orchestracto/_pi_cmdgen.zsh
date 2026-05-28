# Zsh key binding for pi command generation
# Usage: 
#   1. Type your request after ": "
#   2. Press Alt+Enter (or Esc then Enter) to generate command
#   3. The line will be replaced with the generated command
#   4. Press Enter to execute

# The system prompt for command generation
PI_CMDGEN_PROMPT='You are a shell command generator. Given a user'\''s natural language description of what they want to do, output ONLY the shell command that accomplishes it.

# Output Rules

- Output ONLY the command, nothing else
- No explanations, no markdown, no backticks, no code blocks
- The command should work in the current directory of the shell
- If multiple commands are needed, separate with && or put in a subshell
- Use common tools: find, grep, ls, xargs, etc.
- Keep commands concise but correct

Now generate the command for:'

# Generate command from natural language input
pi-cmd() {
    local input="${BUFFER#*: }"
    local result
    
    # Only trigger if line starts with ": "
    if [[ "$BUFFER" != ": "* ]]; then
        zle beep
        return 1
    fi
    
    if [[ -z "$input" ]]; then
        zle beep
        return 1
    fi
    
    # Show "Generating..." indicator
    zle -R "Generating command..."
    
    # Generate the command
    result=$(pi --no-context-files --no-skills --no-prompt-templates --no-extensions --no-tools \
        --system-prompt "$PI_CMDGEN_PROMPT" \
        -p "$input" 2>/dev/null)
    
    # Strip whitespace
    result=$(echo "$result" | tr -d '\n' | xargs)
    
    if [[ -n "$result" ]]; then
        BUFFER="$result"
        zle reset-prompt
    else
        zle beep
        return 1
    fi
}

zle -N pi-cmd

# Bind Alt+Enter to generate command
# In most terminals: Alt+Enter sends ^[m (Escape + m)
bindkey "^[m" pi-cmd

# Also bind Escape+Enter (press Escape then Enter)
# This works in more terminals
bindkey "^[^M" pi-cmd

# Instructions message (shown on first shell load)
echo "pi-cmd: Type ': <command description>' then Alt+Enter to generate shell command"
echo "Example: ': find all python files in src'"