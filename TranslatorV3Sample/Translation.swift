//
//  Translation.swift
//  TranslatorV3Sample
//
//  Created by MSTranslatorMac on 2/15/18.
//  Copyright © 2018 MSTranslatorMac. All rights reserved.
//

import Foundation
import UIKit

class Translation: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {
    
    var fromLangCode = Int()
    var toLangCode = Int()
    
    //*****used after parsing need to put into an array of structs
    struct AllLangDetails: Codable {
        var code = String()
        var name = String()
        var nativeName = String()
        var dir = String()
    }
    var arrayLangInfo = [AllLangDetails]() //array of structs for language info
    
    //*****Formatting JSON for body of request
    struct TranslatedStrings: Codable {
        var text: String
        var to: String
    }
    
    let jsonEncoder = JSONEncoder()
    
    @IBOutlet weak var fromLangPicker: UIPickerView!
    @IBOutlet weak var toLangPicker: UIPickerView!
    @IBOutlet weak var textToTranslate: UITextView!
    @IBOutlet weak var translatedText: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        fromLangPicker.dataSource = self
        toLangPicker.dataSource = self
        fromLangPicker.delegate =  self
        toLangPicker.delegate = self
        
        getLanguages()
        usleep(900000)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //*****IBAction
    
    @IBAction func getTranslationBtn(_ sender: Any) {
        
        fromLangCode = self.fromLangPicker.selectedRow(inComponent: 0)
        toLangCode = self.toLangPicker.selectedRow(inComponent: 0)
        
        print("this is the selected language code ->", arrayLangInfo[fromLangCode].code)
        
        let selectedFromLangCode = arrayLangInfo[fromLangCode].code
        let selectedToLangCode = arrayLangInfo[toLangCode].code
        
        struct encodeText: Codable {
            var text = String()
        }
        
        let azureKey = "31b6016565ac4e1585b1fdb688e42c6d"
        let contentType = "application/json"
        let traceID = "A14C9DB9-0DED-48D7-8BBE-C517A1A8DBB0"
        let host = "dev.microsofttranslator.com"
        let apiURL = "https://dev.microsofttranslator.com/translate?api-version=3.0&from=" + selectedFromLangCode + "&to=" + selectedToLangCode
        
        let text2Translate = textToTranslate.text
        var encodeTextSingle = encodeText()
        var toTranslate = [encodeText]()
        encodeTextSingle.text = text2Translate!
        toTranslate.append(encodeTextSingle)
        
        let jsonToTranslate = try? jsonEncoder.encode(toTranslate)
        let url = URL(string: apiURL)
        var request = URLRequest(url: url!)

        request.httpMethod = "POST"
        request.addValue(azureKey, forHTTPHeaderField: "Ocp-Apim-Subscription-Key")
        request.addValue(contentType, forHTTPHeaderField: "Content-Type")
        request.addValue(traceID, forHTTPHeaderField: "X-ClientTraceID")
        request.addValue(host, forHTTPHeaderField: "Host")
        request.addValue(String(describing: jsonToTranslate?.count), forHTTPHeaderField: "Content-Length")
        request.httpBody = jsonToTranslate
        
        //print(String(data: jsonToTranslate!, encoding: .utf8)!)
        let config = URLSessionConfiguration.default
        let session =  URLSession(configuration: config)
        
        let task = session.dataTask(with: request) { (responseData, response, responseError) in
            
            print("*****this is the response from the request")
            print("this is the response ", response!)
            print("this is the response data ", responseData!)
            
            print(String(data: responseData!, encoding: .utf8)!)
            if responseError != nil {
                print("this is the error ", responseError!)
            }
            print("*****")
            self.parseJson(jsonData: responseData!)
        }
        task.resume()
//        DispatchQueue.main.async {
//            self.translatedText.text = newTranslatedText
//        }
        
    }
    
    
    //*****Class Methods
    
    func parseJson(jsonData: Data) {
        
        //*****TRANSLATION RETURNED DATA*****
        struct ReturnedJson: Codable {
            var translations: [TranslatedStrings]
        }
        struct TranslatedStrings: Codable {
            var text: String
            var to: String
        }
        
        let jsonDecoder = JSONDecoder()
        let langTranslations = try? jsonDecoder.decode(Array<ReturnedJson>.self, from: jsonData)
        let numberOfTranslations = langTranslations!.count - 1
        print(langTranslations!.count)
        print("**********")
        print("This is the translation -> ", langTranslations![0].translations[numberOfTranslations].text)
        print("**********")
        print("This is the language code -> ", langTranslations![0].translations[numberOfTranslations].to)
        
        DispatchQueue.main.async {
            self.translatedText.text = langTranslations![0].translations[numberOfTranslations].text
        }
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        
        var rowCount = Int()
        
        if pickerView == fromLangPicker {
            rowCount = arrayLangInfo.count
        } else if pickerView == toLangPicker {
            rowCount = arrayLangInfo.count
        }
        return rowCount
    }
    
    func pickerView(_ pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {
        var rowContent = String()
        
        if pickerView == fromLangPicker {
            rowContent = arrayLangInfo[row].nativeName
            
        } else if pickerView == toLangPicker {
            rowContent = arrayLangInfo[row].name
        }
        
        let attributedString = NSAttributedString(string: rowContent, attributes: [NSAttributedStringKey.foregroundColor : UIColor.blue])
        
        return attributedString
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        let languageName = row
        print("selected row ", languageName)
    }
    
    //*****CODE FROM PLAYGROUND FOR GETTING LANGUAGES NEED TO MOVE SOME VARS TO CLASS VARS
    func getLanguages() {
        
        let sampleLangAddress = "https://dev.microsofttranslator.com/languages?api-version=3.0&scope=translation"
        
        let url1 = URL(string: sampleLangAddress)
        let jsonLangData = try! Data(contentsOf: url1!)
        
        //*****used in the parsing of request Json
        struct Translation: Codable {
            var translation: [String: LanguageDetails]
            
        }
        struct LanguageDetails: Codable {
            var name: String
            var nativeName: String
            var dir: String
        }
        //*****
        
        let jsonDecoder1 = JSONDecoder()
        let languages = try? jsonDecoder1.decode(Translation.self, from: jsonLangData)
        var eachLangInfo = AllLangDetails(code: " ", name: " ", nativeName: " ", dir: " ") //Use this instance to populate and then append to the array instance
        
        //dump(languages)
        //print(languages!.translation.first?.key as Any)
        //print(languages!.translation.first?.value.name as Any)
        //print(languages!.translation.first?.value.nativeName as Any)
        //print(languages!.translation.first?.value.dir as Any)
        
        for languageValues in languages!.translation.values {
            eachLangInfo.name = languageValues.name
            eachLangInfo.nativeName = languageValues.nativeName
            eachLangInfo.dir = languageValues.dir
            arrayLangInfo.append(eachLangInfo)
        }
        
        let countOfLanguages = languages?.translation.count
        var counter = 0
        
        for languageKey in languages!.translation.keys {
            
            if counter < countOfLanguages! {
                arrayLangInfo[counter].code = languageKey
                counter += 1
            }
        }
        
        //arrayLangInfo.count
        //print(arrayLangInfo[60])
        arrayLangInfo.sort(by: {$0.name < $1.name})
        //print(arrayLangInfo)
    }
    
    
    
}
