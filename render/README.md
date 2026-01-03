# LuminosityHub Render Script Hosting

This project is a Node.js/Express web server for hosting Lua scripts. It allows users to upload scripts, browse available scripts, and retrieve raw script content for use with loadstring in Roblox or similar environments.

## Features
- Upload Lua scripts via a simple web interface
- Browse and search available scripts
- Retrieve raw script content by name (for use with loadstring)
- Copy script URLs for easy integration

## Usage
1. Start the server: `npm start`
2. Visit the web interface to upload or browse scripts
3. Use the provided URLs to load scripts via loadstring

## Folder Structure
- `/scripts` - Stores uploaded Lua scripts
- `/routes` - Express route handlers
- `/public` - Static frontend files

## To Do
- Add authentication (optional)
- Add script versioning (optional)

---

This README will be updated as the project evolves.