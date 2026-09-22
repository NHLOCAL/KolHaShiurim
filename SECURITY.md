# Security

To report a security vulnerability, email [nh.local11@gmail.com](mailto:nh.local11@gmail.com) with a concise description and reproduction steps. Avoid posting exploit details, private data, database backups, or logs in a public issue. Ordinary bugs and feature requests can be filed in [GitHub Issues](https://github.com/NHLOCAL/KolHaShiurim/issues).

The current application is local Windows software. It no longer requires activation, a license file, or a computer hardware fingerprint. Access to transfer destinations is still controlled by the configured user, device, and rabbi permissions. The Windows account running the application also needs appropriate file system permissions.

## Repository history and local data

An earlier revision committed a private signing key, `private.pem`, associated with the former public license verifier. Both the activation mechanism and the key files have been removed from the current source. Git history can still contain those files. Treat that signing key as retired: never use it to sign or verify a new license or for any other purpose. Deleting files from the current tree does not erase historical commits.

The repository has received a focused check for known key material, logs, obsolete sales and activation documents, and generated files. This is not a guarantee that every historical commit or local installation is free of identifying information. Before sharing a clone or logs, inspect its full history and local files for information specific to your environment. No Git history rewrite is part of this transition.

The application stores its SQLite database in the user's Documents directory as `kol_hashiurim.sqlite`. Upgrades use an existing `torah_shiurim.sqlite` in place when the current filename does not exist, preserving its data and WAL sidecars. If both files exist, `kol_hashiurim.sqlite` takes precedence; they are not merged automatically. Settings can be exported to JSON from the Settings tab. Runtime logs are stored in the application's support directory under `logs/app_log.txt`. These files can contain names, device identifiers, file paths, and activity records. Keep them private, and redact relevant details before attaching them to a report.

See [LICENSE](LICENSE) for the project license and [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md) for dependency and optional tool terms.
