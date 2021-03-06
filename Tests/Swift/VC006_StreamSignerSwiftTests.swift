//
//  VC006_StreamSignerSwiftTests.swift
//  VirgilCypto
//
//  Created by Pavel Gorb on 3/3/16.
//  Copyright © 2016 VirgilSecurity. All rights reserved.
//

import XCTest

class VC006_StreamSignerSwiftTests: XCTestCase {

    var toSign: Data! = nil
    
    override func setUp() {
        super.setUp()

        let message = NSString(string: "Message which is need to be signed.")
        self.toSign = message.data(using: String.Encoding.utf8.rawValue, allowLossyConversion:false)
    }
    
    override func tearDown() {
        self.toSign = nil
        super.tearDown()
    }

    func test001_createSigner() {
        let signer = VSCStreamSigner()
        XCTAssertNotNil(signer, "VSCStreamSigner instance should be created.");
    }
    
    func test002_composeAndVerifySignature() {
        // Generate a new key pair
        let keyPair = VSCKeyPair()
        
        // Compose signature:
        // Create the signer
        let signer = VSCStreamSigner()
        // Compose the signature
        var signature = Data()
        do {
            let sis = InputStream(data: self.toSign)
            signature = try signer.signStreamData(sis, privateKey: keyPair.privateKey(), keyPassword: nil)
        }
        catch let error as NSError {
            XCTFail("Error composing the signature: \(error.localizedDescription)")
        }
        
        let verifier = VSCStreamSigner()
        do {
            let vis = InputStream(data: self.toSign)
            try verifier.verifySignature(signature, from: vis, publicKey: keyPair.publicKey())
        }
        catch let error as NSError {
            XCTFail("Error verification the signature: \(error.localizedDescription)")
        }
    }

}
