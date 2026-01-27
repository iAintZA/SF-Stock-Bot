# SuperForest Webhook Script

⚡ **Key Info**

This is **not a traditional bot**. It’s a **webhook-based client-side tracker**, meaning it only works when a player running the script is **online and in-game**.  

- There is **no official API** from the game, so it’s **not possible to create a fully online 24/7 bot**. All notifications rely on a player’s client sending webhook messages.  
- **Anti-AFK** and **auto-reconnect** features only affect the player running the script.  
- **Automatic execution on teleport** requires a script executor (e.g., Synapse). In standard Roblox, the script must be placed in **StarterPlayerScripts**.  

💡 **Limitations**

- Webhook notifications are **per player**, not global for all users.  
- Only tracks **shop categories present in the player’s session**.  
- **Item-specific role pings** occur only when the item is in stock.  

✅ **Features for Players Using the Tracker**

- Real-time **shop restock notifications**  
- **Organized 3-column embeds** showing stock quantities  
- **Global role ping** & **item-specific role pings**  
- **Anti-AFK protection**  
- **Auto reconnect** to the same server  

⚠️ **Note:** This is **client-side only**. It’s a personal stock tracker, not a server-wide bot, and it **cannot run persistently 24/7**.

---

## 🛠 How to Use

1. **Install a Script Executor**  
   - Required for automatic execution.

2. **Place the Script**  
   - loadstring(game:HttpGet("https://raw.githubusercontent.com/iAintZA/SF-Stock-Bot/refs/heads/main/main.lua"))()

3. **Configure Webhooks**  
   - Set up a **Discord webhook** where notifications will be sent.  
   - Optionally, configure **role pings** for specific items.  

4. **Run the Script**  
   - Ensure you are **logged in and in-game**.  
   - The tracker will automatically send notifications for **restocked items**.  
