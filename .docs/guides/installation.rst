Installation
=============

System Requirements
-------------------

- World of Warcraft (Retail or Classic)
- Basic understanding of roleplaying mechanics (recommended)

Installation Steps
------------------

1. **Download the addon**

   Clone the repository or download the latest release::

       git clone https://github.com/FrontierDev/rpengine.git RPEngine

2. **Place in AddOns folder**

   Move the ``RPEngine`` folder to your World of Warcraft AddOns directory:

   - **Windows**: ``C:\Program Files (x86)\World of Warcraft\_retail_\Interface\AddOns\``
   - **macOS**: ``/Applications/World of Warcraft/_retail_/Interface/AddOns/``
   - **Linux**: Check your WoW installation path

3. **Enable in WoW**

   - Open World of Warcraft
   - Click the "AddOns" button on the login screen
   - Locate "RPEngine" and ensure it's checked
   - Reload the UI or restart WoW

4. **First Launch**

   When you log in, RPEngine will:
   - Create default profiles for your character
   - Load the default ruleset and datasets
   - Initialize the UI panels

Troubleshooting
---------------

**AddOn not appearing**
- Verify the folder is in the correct location
- Check that ``RPEngine.toc`` is in the RPEngine directory
- Clear cache: Delete ``WoWCache.exe`` or equivalent

**Errors on login**
- Check the console (``/console scriptErrors 1``)
- Review ``RPEngine.log`` if it exists
- Try disabling other addons to check for conflicts

**Missing UI elements**
- Try ``/reload`` to reset the UI
- Check that no other addons are using similar UI frameworks
