# claude-rot

Watch TikTok, Reels, Shorts, and X while Claude Code works.

## Setup

### Windows

1. Clone to your desktop:
   ```
   git clone https://github.com/YOUR_USERNAME/claude-rot.git %USERPROFILE%\desktop\claude-rot
   ```

2. Add to `%USERPROFILE%\.claude\settings.json`:
   ```json
   {
     "hooks": {
       "UserPromptSubmit": [
         {
           "matcher": "",
           "hooks": [
             {
               "type": "command",
               "command": "powershell.exe -ExecutionPolicy Bypass -File \"%USERPROFILE%\\desktop\\claude-rot\\scripts\\open-brainrot.ps1\" -Action open"
             }
           ]
         }
       ],
       "Stop": [
         {
           "matcher": "",
           "hooks": [
             {
               "type": "command",
               "command": "powershell.exe -ExecutionPolicy Bypass -File \"%USERPROFILE%\\desktop\\claude-rot\\scripts\\open-brainrot.ps1\" -Action close"
             }
           ]
         }
       ],
       "Notification": [
         {
           "matcher": "",
           "hooks": [
             {
               "type": "command",
               "command": "powershell.exe -ExecutionPolicy Bypass -File \"%USERPROFILE%\\desktop\\claude-rot\\scripts\\open-brainrot.ps1\" -Action close"
             }
           ]
         }
       ]
     }
   }
   ```

3. Restart Claude Code.

### macOS

1. Clone to your home folder:
   ```bash
   git clone https://github.com/YOUR_USERNAME/claude-rot.git ~/claude-rot
   chmod +x ~/claude-rot/scripts/open-brainrot.sh
   ```

2. Add to `~/.claude/settings.json`:
   ```json
   {
     "hooks": {
       "UserPromptSubmit": [
         {
           "matcher": "",
           "hooks": [
             {
               "type": "command",
               "command": "~/claude-rot/scripts/open-brainrot.sh open"
             }
           ]
         }
       ],
       "Stop": [
         {
           "matcher": "",
           "hooks": [
             {
               "type": "command",
               "command": "~/claude-rot/scripts/open-brainrot.sh close"
             }
           ]
         }
       ],
       "Notification": [
         {
           "matcher": "",
           "hooks": [
             {
               "type": "command",
               "command": "~/claude-rot/scripts/open-brainrot.sh close"
             }
           ]
         }
       ]
     }
   }
   ```

3. Restart Claude Code.

## License

MIT
