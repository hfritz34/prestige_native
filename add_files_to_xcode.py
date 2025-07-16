#!/usr/bin/env python3
"""
Script to add Swift files to Xcode project that were created outside of Xcode
"""
import os
import subprocess
import sys

def run_command(cmd):
    """Run shell command and return output"""
    try:
        result = subprocess.run(cmd, shell=True, capture_output=True, text=True, check=True)
        return result.stdout.strip()
    except subprocess.CalledProcessError as e:
        print(f"Error running command: {cmd}")
        print(f"Error: {e.stderr}")
        return None

def main():
    # Change to project directory
    project_dir = "/Users/henryfritz/Personal Projects/PrestigeNative"
    os.chdir(project_dir)
    
    # Files to add to Xcode project
    files_to_add = [
        "PrestigeNative/Core/Models/APIEndpoints.swift",
        "PrestigeNative/Core/Models/APIModels.swift", 
        "PrestigeNative/Core/Models/PrestigeModels.swift",
        "PrestigeNative/Core/Models/UserModels.swift",
        "PrestigeNative/Core/Networking/APIClient.swift",
        "PrestigeNative/Core/Networking/AuthManager.swift",
        "PrestigeNative/Core/Networking/Services/FriendsService.swift",
        "PrestigeNative/Core/Networking/Services/ProfileService.swift",
        "PrestigeNative/Core/Networking/Services/SpotifyService.swift",
        "PrestigeNative/Features/Authentication/Components/LoadingButton.swift",
        "PrestigeNative/Features/Authentication/ViewModels/LoginViewModel.swift",
        "PrestigeNative/Features/Authentication/Views/AuthenticationView.swift",
        "PrestigeNative/Features/Authentication/Views/LoginView.swift"
    ]
    
    # Add each file to Xcode project
    for file_path in files_to_add:
        if os.path.exists(file_path):
            print(f"Adding {file_path} to Xcode project...")
            # Use xed command to add file to project
            cmd = f'osascript -e \'tell application "Xcode" to open "{os.path.abspath(file_path)}";\''
            run_command(cmd)
        else:
            print(f"Warning: {file_path} does not exist")
    
    print("Files added to Xcode project. Please check Xcode to confirm they appear in the navigator.")

if __name__ == "__main__":
    main()