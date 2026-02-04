# 🐍 Sonic Snake

A modern, fast-paced snake game built with Flutter featuring dynamic themes, customizable skins, and an integrated music player.

![Flutter](https://img.shields.io/badge/Flutter-3.8.1-02569B?logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.8.1-0175C2?logo=dart)
![License](https://img.shields.io/badge/License-MIT-green.svg)

## ✨ Features

### 🎮 Gameplay
- **Classic Snake Mechanics** - Smooth, responsive controls with modern touch interface
- **Progressive Difficulty** - 20 levels with increasing speed and complexity
- **Dynamic Themes** - Multiple visual themes (Rainforest, Cyber-City, Deep Space)
- **Score System** - Earn coins based on your performance

### 🎨 Customization
- **Unlockable Skins** - 8 unique snake skins with special effects
  - Classic, Neon, Fire, Ice, Galaxy, Rainbow, Shadow, Gold
- **Theme Selection** - Choose from multiple background themes
- **Coin Economy** - Earn coins by playing and unlock premium skins

### 🎵 Music Player
- **Integrated Music Player** - Play your device music while gaming
- **Full Playback Controls** - Play, pause, skip, and previous track
- **Playlist Management** - Browse and select from your music library
- **Modern UI** - Clean, glassmorphic music player interface

### 🎯 Controls
- **Circular D-Pad** - Modern, centered control pad with large touch areas
- **Gesture Support** - Swipe gestures for quick direction changes
- **Responsive Design** - Optimized for various screen sizes

## 📱 Screenshots

*Coming soon*

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (^3.8.1)
- Dart SDK (^3.8.1)
- Android Studio / Xcode (for mobile development)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/tamimurashid/sonic-snake.git
   cd sonic-snake
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Generate launcher icons**
   ```bash
   dart run flutter_launcher_icons
   ```

4. **Generate splash screen**
   ```bash
   dart run flutter_native_splash:create
   ```

5. **Run the app**
   ```bash
   flutter run
   ```

## 🏗️ Build

### Android
```bash
flutter build apk --release
# or for split APKs
flutter build apk --split-per-abi
```

### iOS
```bash
flutter build ios --release
```

## 🎮 How to Play

1. **Start Game** - Tap the play button or select a level from the menu
2. **Control Snake** - Use the circular D-pad to change direction
3. **Collect Food** - Eat food to grow and earn points
4. **Avoid Collisions** - Don't hit walls or yourself
5. **Earn Coins** - Score points to earn coins (1 coin per 50 points)
6. **Unlock Skins** - Use coins to unlock premium snake skins

## 🛠️ Tech Stack

- **Framework**: Flutter
- **Language**: Dart
- **Audio**: audioplayers, on_audio_query
- **Storage**: shared_preferences
- **Permissions**: permission_handler
- **UI**: flutter_animate, google_fonts

## 📦 Dependencies

```yaml
dependencies:
  flutter_animate: ^4.5.0
  google_fonts: ^6.2.1
  audioplayers: ^6.1.0
  on_audio_query: ^2.9.0
  file_picker: ^8.3.7
  permission_handler: ^11.3.1
  shared_preferences: ^2.3.4
  path_provider: ^2.1.5
  device_info_plus: ^11.2.0
  flutter_svg: ^2.0.16
  palette_generator: ^0.3.3+7
```

## 🎨 Features in Detail

### Skin System
Each skin has unique visual properties:
- **Head Color** - Distinct head appearance
- **Body Color** - Custom body gradient
- **Special Effects** - Glow, shimmer, or particle effects
- **Unlock Requirements** - Free or coin-based

### Theme System
Themes provide complete visual overhauls:
- **Background Gradients** - Multi-color gradients
- **Board Styling** - Custom board colors
- **Grid Effects** - Themed grid lines
- **Accent Colors** - UI element theming

### Music Integration
- **Auto-discovery** - Automatically finds music on device
- **Playlist View** - Beautiful playlist interface
- **Now Playing** - Shows current track info
- **Seamless Playback** - Continues playing between games

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 👨‍💻 Author

**Tamimu rashid**
- GitHub: [@tamimurashid](https://github.com/tamimurashid)
- Email: [rashidytamimu@gmail.com](mail to:[rashidytamimu@gmail.com])

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Google Fonts for beautiful typography
- All open-source contributors

## 📞 Support

If you encounter any issues or have questions, please file an issue on the GitHub repository.

---

Made with ❤️ by tamimurashid
