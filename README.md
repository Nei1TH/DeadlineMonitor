# Deadline Monitor

A clean and minimalist macOS deadline tracking application built with **SwiftUI**.

Deadline Monitor gives you full control over your data by storing everything in a local JSON file (Vault). It features a beautiful countdown interface, urgency-based color coding, and automatic cleanup of old tasks.

## Demo
<img width="453" height="553" alt="DM_Demo1" src="https://github.com/user-attachments/assets/225d9cfc-d6ec-4e06-98cc-8e0a16db7861" />

<img width="455" height="549" alt="DM_Demo2" src="https://github.com/user-attachments/assets/6e51d437-6f2e-4bd2-9743-419f100efda4" />

## Features

- **Privacy First**: Your data lives in a local JSON file. You choose where to store it (Documents, iCloud Drive, etc.).
- **Urgency Color Coding**: Visual cues help you prioritize:
  - 🔵 **Blue**: > 2 weeks left
  - 🟢 **Green**: > 1 week left
  - 🟠 **Orange**: > 3 days left
  - 🔴 **Red**: ≤ 3 days left
- **Auto-Cleanup**: Automatically removes completed tasks older than 30 days to keep your list fresh.

## Tech Stack

- **Language**: Swift 5.5+
- **Framework**: SwiftUI

## Getting Started
1) 
1. **Clone the repository**:
   ```bash
   git clone [https://github.com/Nei1TH/DeadlineMonitor]
   ```
2. **Open in Xcode**:
   Double-click `Deadline.xcodeproj`.
3. **Build and Run**:
   Press `Cmd + R` to start the app.

2)
Download compress file in release page

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## License

Distributed under the MIT License. See `LICENSE` for more information.
