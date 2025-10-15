# AI Agent Godot

**Intelligent NPC system with Utility AI for Godot 4.x**

[![Godot](https://img.shields.io/badge/Godot-4.2%2B-blue)](https://godotengine.org)

## 🚀 Quick Start

1. **Install** Godot 4.2+
2. **Open** project in Godot
3. **Play** `main.tscn` (F5)
4. **WASD** to control blue player
5. Red AI agent **patrols → detects → chases → attacks**

## ✨ Features

- 🧠 **Utility AI** decision making
- 🛤️ **NavigationAgent2D** pathfinding
- 🕵️ **RayCast2D** + Area detection
- ⚔️ Combat system (health, damage)
- 🏃 States: Patrol/Chase/Attack/Flee

## 📁 Structure

```
├── project.godot
├── main.tscn
├── player.tscn
├── ai_agent.tscn
└── scripts/
    ├── ai_agent.gd     # AI Brain
    ├── player.gd       # Player controls
    └── game_manager.gd
```

## 🎮 Controls

- **WASD**: Player movement
- **AI**: Automatic (patrol, chase, attack)

## 🔧 Setup

1. **NavigationRegion2D** in `main.tscn`
2. **Bake NavigationPolygon** (hammer icon)
3. **Check Collision Layers** in Project Settings

## 🧪 Testing

- Agent patrols between points
- Detects player (200px radar)
- Chases with pathfinding
- Attacks in range (50px)
- Flees when health < 30%

## 🐛 Troubleshooting

| Issue | Fix |
|-------|-----|
| Agent stuck | Bake NavigationPolygon |
| No detection | Check collision masks |
| Script error | Verify `res://scripts/` paths |

## 🔌 Extensions

- **Multi-agents**
- **Godot RL Agents**
- **Steering AI** (GDQuest)
- **Cover system**

## 📚 Resources

- [Godot Navigation Docs](https://docs.godotengine.org/en/stable/tutorials/navigation/)
- [Utility AI Guide](https://www.gamedeveloper.com/design/utility-ai-in-games)

## 🤝 Contributing

1. Fork project
2. Create feature branch
3. Commit changes
4. Pull Request

## 📄 License

[MIT](LICENSE)

---

**⭐ Star if useful!**  
*Built with Godot 4.x*
