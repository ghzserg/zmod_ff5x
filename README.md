# AD5X
 - Compatible with Bambu Studio, better management of the prime tower
   ([3MF](https://github.com/function3d/zmod_ff5x/raw/refs/heads/1.6/PinkyWings_FireDragon.3mf))
  - Purge sequences fully controlled by Bambu Studio (same behavior as
   Bambu Lab printers)
   - Accurate time and material usage estimates
   - 24 mm retraction before filament cut on every color change (saves ~7
   meters of filament across 300 color changes)
   - Reduced purge multiplier (≈ 0.7) possible without color mixing in
   most prints
   - “Flush into object infill” and “flush into object supports”
   effectively reduce filament waste
   - **Material-to-waste ratio rarely exceeds 50%, even on 4-color prints**
   - **Mainsail displays true colors directly from the slicer**
   - **45 seconds color change time**
   - Bed leveling before print (Level On/Off)
   - External spool printing (IFS On/Off)
   - Backup printing mode – up to 4 kg of uninterrupted printing (Backup
   On/Off)
  - Automatic fallback when IFS runs out: the remaining filament in the
   printhead is used until the next color change
   - Filament state detection at print_start to identify the active
   filament in the extruder
   - Detection of jams, breaks, or filament runout
   - Improved routine for automatic print recovery after power outages or
   errors

<img width="1509" height="800" alt="image" src="https://github.com/user-attachments/assets/1b265dbb-cb3f-47e2-84d0-d1f6e6c8948e" />

<img width="1200" height="799" alt="image" src="https://github.com/user-attachments/assets/149a324b-589d-4bb4-a1df-cc5baa7e0e3f" />

<img width="964" height="729" alt="image" src="https://github.com/user-attachments/assets/61e10f93-6831-48b3-9e8b-338a4969ccb9" />

## How to install

- For users with experience in klipper, python, ssh, etc. Do not proceed if you do not know what you are doing.

- Install [zmod](https://github.com/ghzserg/zmod) following the instructions.

- Change the native display to Guppyscreen DISPLAY_OFF.

- Log in to your AD5X via ssh.

- Download and run the update.sh script

	`curl -L -o update.sh https://raw.githubusercontent.com/function3d/zmod_ff5x/refs/heads/1.6/update.sh`

	`./update.sh`

- Use this [3MF](https://github.com/function3d/zmod_ff5x/raw/refs/heads/1.6/PinkyWings_FireDragon.3mf) with Bambu Studio (from there you can save settings such as user profiles)

- Download the post-processing scripts purge_tower_exclude_object.py and ifs_colors.py to your PC and adapt the paths in the Bambu Studio post-processing scripts.


<img width="1005" height="1113" alt="image" src="https://github.com/user-attachments/assets/f6812bbf-ffd2-45d0-85fb-2e95d7d04b9b" />
<img width="1200" height="1600" alt="image" src="https://github.com/user-attachments/assets/8ad8ce59-6f45-44ef-88ec-be9ecdcfb7f0" />



