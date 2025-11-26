# Floe

An AI-powered writing companion for novelists. Floe provides real-time scene analysis with intelligent insights to help you craft better stories.

## Features

### 🎭 AI Scene Analysis
- **Automatic scene detection** using standard manuscript formatting (two blank lines)
- **Real-time analysis** powered by local LLM (Ollama)
- Analyzes:
  - Characters present in the scene
  - Setting and time of day
  - Point of view and narrative tone
  - Stakes and emotional tension
  - Sensory details (sight, sound, touch, taste, smell)
  - Dialogue/narrative balance
  - Echo words (repeated words that may need attention)

### 💡 AI Hunches
- Get intelligent suggestions about:
  - Pacing and rhythm
  - Emotional resonance
  - Missing elements
  - Opportunities for improvement
  - Clarity and coherence

### ✍️ Distraction-Free Writing
- Clean, minimalist interface
- Focus mode that highlights current sentence
- Customizable fonts and line spacing
- Word count tracking
- Auto-save functionality

### 📊 Scene Information Panel
- Persistent right-margin analysis display
- Updates automatically as you write
- Always-visible insights without interrupting flow
- Hides in fullscreen mode

## Requirements

### To Use Floe
- **Windows** (macOS and Linux support coming soon)
- **Ollama** with a language model installed (default: llama3.2:3b)

### To Build from Source
- Flutter SDK 3.0.0 or higher
- Windows development tools (Visual Studio 2019 or later)
- Git

## Installation

### Download Pre-built Binary
Download the latest release from the [Releases](../../releases) page.

### Using Ollama
1. Install [Ollama](https://ollama.ai)
2. Pull the model:
   ```bash
   ollama pull llama3.2:3b
   ```
3. Run Ollama:
   ```bash
   ollama run llama3.2:3b
   ```
4. Launch Floe

## Building from Source

```bash
# Clone the repository
git clone https://github.com/YOUR_USERNAME/floe.git
cd floe

# Get dependencies
flutter pub get

# Build for Windows
flutter build windows --release

# The executable will be at:
# build/windows/x64/runner/Release/floe.exe
```

## Usage

### Keyboard Shortcuts
- **Ctrl+N**: New document
- **Ctrl+O**: Open file
- **Ctrl+S**: Save As
- **Ctrl+A**: Force scene analysis
- **Ctrl+D**: Toggle dark mode
- **Ctrl+F**: Toggle focus mode
- **Ctrl+Shift+W**: Toggle word count
- **F11**: Toggle fullscreen
- **Escape**: Show/hide file menu

### Scene Breaks
Use **two blank lines** (press Enter 3 times) to separate scenes. Floe will automatically detect and analyze each scene independently.

### Automatic Analysis
Floe analyzes your writing automatically when:
- You stop typing for 5 seconds
- At least 50 words have been added
- At least 30 seconds have passed since the last analysis

Press **Ctrl+A** to force an immediate analysis.

## Configuration

Floe uses Ollama running on `http://localhost:11434` by default. The AI model is configured for:
- **Model**: llama3.2:3b
- **Temperature**: 0.3 (for consistent analysis)
- **Max tokens**: 500

## Privacy

- All AI processing happens **locally** on your machine
- No data is sent to external servers
- Your writing stays on your computer
- Auto-save files are stored in your Documents folder

## Roadmap

- [ ] macOS support
- [ ] Linux support
- [ ] Customizable AI model selection
- [ ] Export scene analysis reports
- [ ] Character tracking across chapters
- [ ] Writing statistics and trends
- [ ] Custom scene break markers
- [ ] Project management features

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

[Choose your license - MIT, Apache 2.0, etc.]

## Acknowledgments

- Built with [Flutter](https://flutter.dev)
- AI powered by [Ollama](https://ollama.ai)
- Fonts: Lora and IBM Plex Mono

---

**Floe** - Flow with your story
