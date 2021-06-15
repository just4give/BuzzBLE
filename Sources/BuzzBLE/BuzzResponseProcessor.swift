//
// Copyright (c) Chris Bartley 2020. Licensed under the MIT license. See LICENSE file.
//

import Foundation
import os

fileprivate extension OSLog {
   static let log = OSLog(category: "BuzzResponseProcessor")
}

protocol BuzzResponseProcessorDelegate: AnyObject {
   func handleUnknown(command: String)
   func handleResponseMessage(message: String, forCommand command: Buzz.Command)
   func handleUnsolicitedResponse(message: String)
}

class BuzzResponseProcessor {
   static private let startDelimiter: String = "{"
   static private let endDelimiter: String = "\r\nble_cli:~$ "

   weak var delegate: BuzzResponseProcessorDelegate?

   private var remainingResponse = ""

   func process(response newResponse: String) {
      // append the new to what we already have acquired but didn't consume
      //print("callinng process New = \(newResponse)")
      //print("callinng process Remaining = \(remainingResponse)")
      remainingResponse += newResponse
      

      // Start by splitting on the ending delimiter, resulting in N pieces.  This should yield N-1 complete responses.
      let responses = remainingResponse.components(separatedBy: BuzzResponseProcessor.endDelimiter)
      
      
      
      // loop over all the pieces, but we skip the last one because it's guaranteed to not contain a complete response
    
        let lastEnum = responses[responses.count - 1]
        var count = responses.count - 1
        var unsolicited = false
        if lastEnum != ""{
              count = responses.count
              unsolicited = true
        }
    
    print("R = \(responses) \n +++++++++ \n")
    print("unsolicited \(unsolicited)")
    
      for (i, response) in responses.enumerated() {
         if i < count {
            
            // we've found a complete response (i.e. command + message) so find the index of the first occurrence of
            // the startDelimiter and treat everything before it as the command and everything after as the message body
            if let startRange = response.range(of: BuzzResponseProcessor.startDelimiter) {
               // pick out the command string
               let commandStr = String(response[..<startRange.lowerBound])
               let message = String(response[startRange.lowerBound...])
               //print("### RX message \(message) with command \(commandStr)" )
               // make sure this is a known command
               if let command = Buzz.Command(rawValue: commandStr) {
                  // pick out the message
                  
                  // notify the delegate that we have a valid command and message
                  delegate?.handleResponseMessage(message: message, forCommand: command)
               }else if unsolicited == true {
                 remainingResponse = ""
                 delegate?.handleUnsolicitedResponse(message: message)
               }
               else {
                  delegate?.handleUnknown(command: commandStr)
               }
            }
            else {
               os_log("BuzzResponseProcessor.process failed to find start delimiter in response=%s", log: OSLog.log, type: .debug, response)
            }
            
         }
         else {
            // this last bit becomes our new remainingResponse, to get consumed next time around
            remainingResponse = response
         }
      }
   }
}
