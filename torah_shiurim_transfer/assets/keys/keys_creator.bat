@echo off

openssl genpkey -algorithm RSA -out private.pem -pkeyopt rsa_keygen_bits:2048


openssl rsa -in private.pem -pubout -out public.pem

pause