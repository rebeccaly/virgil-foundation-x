//
//  VC004_StreamCryptorSwiftTests.swift
//  VirgilCypto
//
//  Created by Pavel Gorb on 3/3/16.
//  Copyright © 2016 VirgilSecurity. All rights reserved.
//

import XCTest

class VC004_StreamCryptorSwiftTests: XCTestCase {

    var toEncrypt: NSData! = nil
    
    override func setUp() {
        super.setUp()
        
        let message = NSString(string: "Secret message which is necessary to be encrypted.")
        self.toEncrypt = message.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)
    }
    
    override func tearDown() {
        self.toEncrypt = nil
        
        super.tearDown()
    }

    func test001_createCryptor() {
        let cryptor = VSSStreamCryptor()
        XCTAssertNotNil(cryptor, "VSSStreamCryptor instance should be created.");
    }
    
    func test002_keyBasedEncryptDecrypt() {
        // Generate a new key pair
        let keyPair = VSSKeyPair()
        // Generate a public key id
        let recipientId = NSUUID().UUIDString
        // Encrypt:
        // Create a cryptor instance
        let cryptor = VSSStreamCryptor()
        // Add a key recepient to enable key-based encryption
        do {
            try cryptor.addKeyRecipient(recipientId, publicKey: keyPair.publicKey(), error: ())
        }
        catch let error as NSError {
            print("Error adding key recipient: \(error.localizedDescription)")
            XCTFail()
        }
        
        let eis = NSInputStream(data: self.toEncrypt)
        let eos = NSOutputStream(toMemory: ())
        do {
            try cryptor.encryptDataFromStream(eis, toStream: eos, embedContentInfo: true)
        }
        catch let error as NSError {
            XCTFail("Error encrypting input stream: \(error.localizedDescription)")
        }

        let encryptedData = eos.propertyForKey(NSStreamDataWrittenToMemoryStreamKey) as! NSData
        XCTAssertTrue(encryptedData.length > 0, "The data encrypted with key-based encryption should have an actual content.")

        // Decrypt:
        // Create a completely new instance of the VCCryptor object
        let decryptor = VSSStreamCryptor()
        
        let dis = NSInputStream(data: encryptedData)
        let dos = NSOutputStream(toMemory: ())
        do {
            try decryptor.decryptFromStream(dis, toStream: dos, recipientId: recipientId, privateKey: keyPair.privateKey(), keyPassword: nil)
        }
        catch let error as NSError {
            XCTFail("Error decrypting data: \(error.localizedDescription)")
        }
        let plainData = dos.propertyForKey(NSStreamDataWrittenToMemoryStreamKey) as! NSData
        XCTAssertTrue(plainData.length > 0, "Decrypted data should contain actual data.")
        XCTAssertEqual(plainData, self.toEncrypt, "Initial data and decrypted data should be equal.")
    }
    
    func test003_passwordBasedEncryptDecrypt() {
        // Encrypt:
        let password = "secret"
        // Create a cryptor instance
        let cryptor = VSSStreamCryptor()
        // Add a password recepient to enable password-based encryption
        do {
            try cryptor.addPasswordRecipient(password, error: ())
        }
        catch let error as NSError {
            print("Error adding password recipient: \(error.localizedDescription)")
            XCTFail()
        }
        
        let eis = NSInputStream(data: self.toEncrypt)
        let eos = NSOutputStream(toMemory: ())
        do {
            try cryptor.encryptDataFromStream(eis, toStream: eos, embedContentInfo: false)
        }
        catch let error as NSError {
            XCTFail("Error encrypting data: \(error.localizedDescription)")
        }
        let encryptedData = eos.propertyForKey(NSStreamDataWrittenToMemoryStreamKey) as! NSData
        XCTAssertTrue(encryptedData.length > 0, "The data encrypted with password-based encryption should have an actual content.");
        
        var contentInfo = NSData()
        do {
            contentInfo = try cryptor.contentInfoWithError()
        }
        catch let error as NSError {
            XCTFail("Error getting content info from cryptor: \(error.localizedDescription)")
        }
        XCTAssertTrue(contentInfo.length > 0, "Content Info should contain necessary information.");
        // Decrypt:
        // Create a completely new instance of the VCCryptor object
        let decryptor = VSSStreamCryptor()
        do {
            try decryptor.setContentInfo(contentInfo, error: ())
        }
        catch let error as NSError {
            XCTFail("Error setting content info to decryptor: \(error.localizedDescription)")
        }
        
        let dis = NSInputStream(data: encryptedData)
        let dos = NSOutputStream(toMemory: ())
        do {
            try decryptor.decryptFromStream(dis, toStream: dos, password: password)
        }
        catch let error as NSError {
            XCTFail("Error decrypting data: \(error.localizedDescription)")
        }
        
        let plainData = dos.propertyForKey(NSStreamDataWrittenToMemoryStreamKey) as! NSData
         XCTAssertTrue(plainData.length > 0, "The data decrypted with password-based decryption should have an actual content.");
        XCTAssertEqual(plainData, self.toEncrypt, "Initial data and decrypted data should be equal.")
    }

}