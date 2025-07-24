# GEMINI.md

## Project Description

This repository contains a secure and automated audio file transfer system for Torah lecture recordings. It enables controlled access and transfer of audio files from external recording devices to local directories, based on preconfigured permissions.

## Objective

To facilitate authorized users in securely transferring audio recordings from specific folders within approved USB devices to corresponding local directories on a computer. The system enforces strict access controls, allowing only permitted files to be copied to designated folders associated with specific rabbis.

## Components

### 1. Admin Panel

A configuration interface used by system administrators to define:

- Device recognition via unique serial number.
- The allowed source folder on the device (e.g., `records/`).
- One or more destination folders on the local file system, each associated with a rabbi.
- The mapping between serial numbers, users, and allowed rabbis.

### 2. User Panel

An interface that automatically activates when an approved device is connected. It enables the user to:

- View the list of available recordings in the allowed source folder.
- Select a rabbi from the list of permitted rabbis.
- Enter a title/topic for the lecture.
- Automatically assign the current date (with manual override option).
- Copy the selected file to the appropriate destination folder.

Post-transfer, the user:

- May only view, rename, or delete the file they just copied.
- Has no access to other files or folders.

### 3. Security Constraints

- File operations are restricted to the specified source and destination directories.
- The user has no access to the general file system of the computer or the USB device.
- Read, write, and edit permissions are strictly enforced via the admin configuration.