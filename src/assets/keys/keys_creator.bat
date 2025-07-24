@echo off
REM Ask for user confirmation
echo Are you sure you want to generate a new RSA key pair?
choice /m "Confirm"

if errorlevel 2 (
    echo Operation cancelled.
    pause
    exit /b
)

REM Generate a new RSA private key (2048 bits)
echo Generating RSA private key...
openssl genpkey -algorithm RSA -out private.pem -pkeyopt rsa_keygen_bits:2048

REM Extract the public key from the private key
echo Extracting public key from private key...
openssl rsa -in private.pem -pubout -out public.pem

REM Pause to allow user to see the result
echo Operation completed.
pause
