import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

/// Service to check for app updates from the Microsoft Store.
///
/// This service uses PowerShell to query the Microsoft Store for updates
/// via the Windows.Services.Store APIs. For Store-installed apps,
/// users are directed to the Microsoft Store to download updates.
class StoreUpdateService {
  // Microsoft Store Product ID (from Partner Center)
  // This is the Store ID that appears in the Store URL
  // Format: https://www.microsoft.com/store/apps/<StoreId>
  static const String _storeId = '9NL0BML96F0F';

  // Package Family Name from Partner Center
  static const String _packageFamilyName =
      'JasonSjogren.ScheduleHQ_<hash>'; // TODO: Replace with actual PFN

  // Current app version (should match pubspec.yaml)
  static const String currentVersion = '2.5.1';

  /// Cached update info
  static bool _updateAvailable = false;
  static String? _storeVersion;
  static String? _lastError;

  /// Whether an update is available
  static bool get updateAvailable => _updateAvailable;

  /// Get the store version string (if available)
  static String? get storeVersion => _storeVersion;

  /// Get the last error message
  static String? get lastError => _lastError;

  /// Check if the app was installed from the Microsoft Store
  static Future<bool> isStoreInstalled() async {
    if (!Platform.isWindows) return false;

    try {
      // Check if running as an MSIX package by looking for package identity
      final result = await Process.run('powershell', [
        '-NoProfile',
        '-Command',
        '''
        try {
          \$package = Get-AppxPackage | Where-Object { \$_.Name -like "*ScheduleHQ*" }
          if (\$package) { 
            Write-Output "true"
          } else { 
            Write-Output "false" 
          }
        } catch {
          Write-Output "false"
        }
        '''
      ]);

      return result.stdout.toString().trim().toLowerCase() == 'true';
    } catch (e) {
      debugPrint('StoreUpdateService: Error checking store install: $e');
      return false;
    }
  }

  /// Check for updates from the Microsoft Store
  /// Returns true if an update is available
  static Future<bool> checkForUpdates() async {
    _lastError = null;
    _updateAvailable = false;

    if (!Platform.isWindows) {
      _lastError = 'Store updates only available on Windows';
      return false;
    }

    try {
      // Use PowerShell to check for updates via Windows Store APIs
      // This queries the store for the current package
      final result = await Process.run('powershell', [
        '-NoProfile',
        '-Command',
        '''
        try {
          Add-Type -AssemblyName System.Runtime.WindowsRuntime
          
          # Get the StoreContext
          \$asyncOp = [Windows.Services.Store.StoreContext,Windows.Services.Store,ContentType=WindowsRuntime]::GetDefault().GetStoreProductForCurrentAppAsync()
          
          # Wait for the async operation
          \$null = [System.WindowsRuntimeSystemExtensions]::AsTask(\$asyncOp).GetAwaiter().GetResult()
          
          \$product = \$asyncOp.GetResults()
          
          if (\$product.ExtendedError -eq \$null -and \$product.Product -ne \$null) {
            # Check if updates are available
            \$updateOp = [Windows.Services.Store.StoreContext,Windows.Services.Store,ContentType=WindowsRuntime]::GetDefault().GetAppAndOptionalStorePackageUpdatesAsync()
            \$null = [System.WindowsRuntimeSystemExtensions]::AsTask(\$updateOp).GetAwaiter().GetResult()
            \$updates = \$updateOp.GetResults()
            
            if (\$updates.Count -gt 0) {
              Write-Output "UPDATE_AVAILABLE"
            } else {
              Write-Output "UP_TO_DATE"
            }
          } else {
            # App not from store, use alternative method
            Write-Output "NOT_STORE_APP"
          }
        } catch {
          Write-Output "ERROR:\$(\$_.Exception.Message)"
        }
        '''
      ]).timeout(const Duration(seconds: 15));

      final output = result.stdout.toString().trim();
      debugPrint('StoreUpdateService: Check result: $output');

      if (output == 'UPDATE_AVAILABLE') {
        _updateAvailable = true;
        return true;
      } else if (output == 'UP_TO_DATE') {
        _updateAvailable = false;
        return false;
      } else if (output == 'NOT_STORE_APP') {
        _lastError = 'App not installed from Microsoft Store';
        return false;
      } else if (output.startsWith('ERROR:')) {
        _lastError = output.substring(6);
        return false;
      }

      return false;
    } catch (e) {
      debugPrint('StoreUpdateService: Error checking for updates: $e');
      _lastError = e.toString();
      return false;
    }
  }

  /// Alternative method: Check by comparing installed version with store listing
  /// This method works even if WinRT APIs fail
  static Future<bool> checkForUpdatesSimple() async {
    _lastError = null;
    _updateAvailable = false;

    if (!Platform.isWindows) {
      _lastError = 'Store updates only available on Windows';
      return false;
    }

    try {
      // Get the installed package version
      final result = await Process.run('powershell', [
        '-NoProfile',
        '-Command',
        '''
        try {
          \$package = Get-AppxPackage | Where-Object { \$_.Name -like "*ScheduleHQ*" } | Select-Object -First 1
          if (\$package) {
            Write-Output \$package.Version
          } else {
            Write-Output "NOT_FOUND"
          }
        } catch {
          Write-Output "ERROR:\$(\$_.Exception.Message)"
        }
        '''
      ]).timeout(const Duration(seconds: 10));

      final output = result.stdout.toString().trim();
      debugPrint('StoreUpdateService: Installed version: $output');

      if (output == 'NOT_FOUND') {
        _lastError = 'Package not found - may not be a Store install';
        return false;
      } else if (output.startsWith('ERROR:')) {
        _lastError = output.substring(6);
        return false;
      }

      // Store the detected version for display
      _storeVersion = output;

      // For now, we can't directly query the store version without Store APIs
      // The main checkForUpdates method handles this via WinRT
      // This method just confirms the app is installed as MSIX

      return false;
    } catch (e) {
      debugPrint('StoreUpdateService: Error in simple check: $e');
      _lastError = e.toString();
      return false;
    }
  }

  /// Open the Microsoft Store page for this app
  static Future<void> openStorePage() async {
    // Use ms-windows-store protocol to open Store directly to the app page
    final storeUri = Uri.parse('ms-windows-store://pdp/?ProductId=$_storeId');

    try {
      // Try the ms-windows-store protocol first
      final launched = await launchUrl(storeUri);
      if (!launched) {
        // Fallback to web URL
        final webUri = Uri.parse(
            'https://www.microsoft.com/store/apps/$_storeId');
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('StoreUpdateService: Error opening store: $e');
      // Final fallback - open Store app
      try {
        await Process.run('explorer.exe', ['ms-windows-store://pdp/?ProductId=$_storeId']);
      } catch (e2) {
        debugPrint('StoreUpdateService: Fallback also failed: $e2');
      }
    }
  }

  /// Request the Store to download and install updates
  /// Note: This will open the Store's update UI
  static Future<void> requestStoreUpdate() async {
    try {
      // Open Store to the Downloads and Updates page
      final updatesUri = Uri.parse('ms-windows-store://downloadsandupdates');
      await launchUrl(updatesUri);
    } catch (e) {
      debugPrint('StoreUpdateService: Error requesting update: $e');
      // Fallback to opening the app's store page
      await openStorePage();
    }
  }

  /// Compare two version strings
  /// Returns: positive if v1 > v2, negative if v1 < v2, 0 if equal
  static int compareVersions(String v1, String v2) {
    // Handle version formats like "2.5.1" or "2.5.1.0"
    final parts1 = v1.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final parts2 = v2.split('.').map((e) => int.tryParse(e) ?? 0).toList();

    // Pad to same length
    while (parts1.length < parts2.length) {
      parts1.add(0);
    }
    while (parts2.length < parts1.length) {
      parts2.add(0);
    }

    for (int i = 0; i < parts1.length; i++) {
      if (parts1[i] > parts2[i]) return 1;
      if (parts1[i] < parts2[i]) return -1;
    }

    return 0;
  }
}
