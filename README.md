# claude-rot

Watch TikTok and Reels while Claude Code works.

Opens browser windows with social media whenever Claude Code starts a task, closes them when it's done.

## Platforms

Opens 4 windows tiled on your screen:
- TikTok
- Instagram Reels
- YouTube Shorts
- X (Twitter)

## Requirements

- [Claude Code](https://claude.ai/code) CLI
- Google Chrome

## Installation

### macOS

1. Clone this repo:
   ```bash
   git clone https://github.com/YOUR_USERNAME/claude-rot.git
   cd claude-rot
   ```

2. Make the script executable:
   ```bash
   chmod +x scripts/open-brainrot.sh
   ```

3. Add the hooks to your Claude Code settings. Open `~/.claude/settings.json` and add:
   ```json
   {
     "hooks": {
       "PreToolUse": [
         {
           "matcher": "Bash|Edit|Write|Read|Glob|Grep|Task",
           "hooks": [
             {
               "type": "command",
               "command": "/path/to/claude-rot/scripts/open-brainrot.sh open"
             }
           ]
         }
       ],
       "PostToolUse": [
         {
           "matcher": "Bash|Edit|Write|Read|Glob|Grep|Task",
           "hooks": [
             {
               "type": "command",
               "command": "/path/to/claude-rot/scripts/open-brainrot.sh close"
             }
           ]
         }
       ]
     }
   }
   ```

4. Replace `/path/to/claude-rot` with the actual path where you cloned the repo.

5. Use Claude Code normally. Windows will open/close automatically!

### Windows

1. Clone this repo:
   ```powershell
   git clone https://github.com/YOUR_USERNAME/claude-rot.git
   cd claude-rot
   ```

2. Add the hooks to your Claude Code settings. Open `%USERPROFILE%\.claude\settings.json` and add:
   ```json
   {
     "hooks": {
       "PreToolUse": [
         {
           "matcher": "Bash|Edit|Write|Read|Glob|Grep|Task",
           "hooks": [
             {
               "type": "command",
               "command": "powershell -ExecutionPolicy Bypass -File \"C:\\path\\to\\claude-rot\\scripts\\open-brainrot.ps1\" -Action open"
             }
           ]
         }
       ],
       "PostToolUse": [
         {
           "matcher": "Bash|Edit|Write|Read|Glob|Grep|Task",
           "hooks": [
             {
               "type": "command",
               "command": "powershell -ExecutionPolicy Bypass -File \"C:\\path\\to\\claude-rot\\scripts\\open-brainrot.ps1\" -Action close"
             }
           ]
         }
       ]
     }
   }
   ```

3. Replace `C:\\path\\to\\claude-rot` with the actual path where you cloned the repo.

4. Use Claude Code normally. Windows will open/close automatically!

## Customization

Edit the `$urls` array (Windows) or `URLS` array (macOS) in the script to change which sites open.

## How It Works

Claude Code has a [hooks system](https://docs.anthropic.com/en/docs/claude-code/hooks) that runs commands before and after tool use.

- `PreToolUse` hook → runs `open` → opens browser windows
- `PostToolUse` hook → runs `close` → closes browser windows

## Credits

Inspired by [claude-brainrot](https://github.com/unoptimal/claude-brainrot) by unoptimal.

## License

MIT
