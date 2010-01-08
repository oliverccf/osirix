/*=========================================================================
 Program:   OsiriX
 
 Copyright (c) OsiriX Team
 All rights reserved.
 Distributed under GNU - GPL
 
 See http://www.osirix-viewer.com/copyright.html for details.
 
 This software is distributed WITHOUT ANY WARRANTY; without even
 the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
 PURPOSE.
 =========================================================================*/

typedef enum
{
	RequirePeerCertificate = 0,
	VerifyPeerCertificate,
	IgnorePeerCertificate
} TLSCertificateVerificationType;

#define TLS_SEED_FILE @"/tmp/OsiriXTLSSeed"
#define TLS_WRITE_SEED_FILE "/tmp/OsiriXTLSSeedWrite"
#define TLS_PRIVATE_KEY_FILE @"/tmp/OsiriXTLSKey"
#define TLS_CERTIFICATE_FILE @"/tmp/OsiriXTLSCertificate"
#define TLS_TRUSTED_CERTIFICATES_DIR @"/tmp/OsiriXTLSTrustedCertificates/" 
#define TLS_KEYCHAIN_IDENTITY_NAME @"com.osirixviewer.dicomtlsclient"
#define TLS_PRIVATE_KEY_PASSWORD @"SuperSecretPassword"