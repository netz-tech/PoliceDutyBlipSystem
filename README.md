# 🚔 NTPoliceDutyBlipSystem

A fully customizable **Police Duty & Blip System** for your FiveM server.
This script is **standalone**, meaning it does not require a framework—but it **must be configured properly** before use.

It includes:

* Duty toggling system
* Custom blips for active units
* Department-based setup
* Discord webhook logging
* UI with custom department images



## 📦 Features

* ✅ Standalone (no ESX/QB required) - MAINLY MEANT FOR VMENU / NDCORE or Similar
* ✅ Customizable department commands
* ✅ Configurable blip colors & styles
* ✅ Discord role-based permissions
* ✅ Webhook logging for actions
* ✅ UI menu with custom department images
* ✅ Weapon loadouts per department



## ⚙️ Installation

1. Download or clone the resource into your server’s `resources` folder
2. Add the resource to your `server.cfg`:

   ```
   ensure PoliceDutyBlipSystem
   ```
3. Restart your server
4. Configure all required files (see below)



## 🛠️ Configuration Guide

### 📁 `config.lua`

This is your **main configuration file**.

Edit the following:

* **Webhooks** → Add your Discord webhook URLs for logging
* **Blip Settings** → Change colors, sprites, names, etc.
* **Departments** → Define department names and commands



### 📁 `server.lua`

Handles **permissions and Discord integration**.

You MUST:

* Add your **exact Discord role names**
* Add **role IDs**
* ⚠️ **IMPORTANT:** Don’t forget to configure **line 329** (required for proper role checking)



### 📁 `client.lua`

Controls what players receive when going on duty.

You can:

* Customize **weapons and attachments**
* Set different loadouts per department

⚠️ Note: Fire/Rescue currently receives weapons by default—adjust this if needed.



### 📁 `html/script.js`

Controls the **UI image display**.

* Set the **image names** used in the menu
* Image names must **match exactly** with files inside:

  ```
  ui/images/departments
  ```



### 🖼️ Department Images

Location:

```
ui/images/departments
```

You can:

* Add custom department logos
* Customize:

  * Header badge (Server Logo)
  * Off-duty image

⚠️ File names must match what’s defined in `script.js`



## 🔗 Webhook Logging

Supports Discord logging for:

* Going on/off duty
* Department changes
* Other system events

Make sure:

* Webhook URLs are valid
* Proper formatting is maintained in `config.lua`



## ⚠️ Important Notes

* This script **will NOT work out-of-the-box** without configuration
* Double-check:

  * Discord Role IDs
  * Department names
  * Image file names
* Keep everything consistent (case-sensitive where applicable)



## 🧩 Customization Tips

* Use different blip colors per department for better visibility
* Create unique loadouts to match your server’s realism level
* Add/remove departments based on your server structure



## 📞 Support

If something isn’t working:

* Recheck all config files
* Verify Discord role setup
* Ensure all file names match correctly



## 📜 License

Feel free to modify and use this script for your server.
Do not redistribute without proper credit.



💡 *Built for flexibility, designed for realism.*
