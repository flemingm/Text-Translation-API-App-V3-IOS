//
//  Transliteration.swift
//  TranslatorV3Sample
//
//  Created by MSTranslatorMac on 2/15/18.
//  Copyright © 2018 MSTranslatorMac. All rights reserved.
//

import Foundation
import UIKit

class TransliterationUIDel: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {
    
    @IBOutlet weak var languageName: UIPickerView!
    @IBOutlet weak var fromScriptBtn1: UIButton!
    @IBOutlet weak var fromScriptBtn2: UIButton!
    @IBOutlet weak var toScriptBtn1: UIButton!
    @IBOutlet weak var toScriptBtn2: UIButton!
    @IBOutlet weak var toScriptBtn3: UIButton!
    @IBOutlet weak var toScriptBtn4: UIButton!
    @IBOutlet weak var textToTransliterate: UITextView!
    @IBOutlet weak var transliteratedText: UITextView!
    
    var languageCode = String()
    var fromLangScript = String()
    var toLangScript = String()
    let jsonEncoder = JSONEncoder()
    let jsonDecoder = JSONDecoder()
    
    //Setup struct vars
    var transliterateLangData = [TransliterationAll]()
    var transliterateLangDataEach = TransliterationAll()
    var scriptLangDetailsSingle = ScriptLangDetails()
    var toScriptDetails = ToScripts()
    
 

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        textToTransliterate.delegate = self
        self.hideKeyboardWhenTappedAround()
        
        languageName.delegate = self
        languageName.dataSource = self
        
        getLanguages()
    }
    
    
    @IBAction func fromScriptBtn1Pressed(_ sender: Any) {
        fromScriptBtn1.backgroundColor = UIColor.orange
        fromScriptBtn2.backgroundColor = UIColor.lightGray
        toScriptBtn3.backgroundColor = UIColor.lightGray
        toScriptBtn4.backgroundColor = UIColor.lightGray
        fromLangScript = (fromScriptBtn1.titleLabel?.text)!
    }
    
    
    @IBAction func fromScriptBtn2Pressed(_ sender: AnyObject) {
        
        if fromScriptBtn2.titleLabel?.text != "--" {
            fromScriptBtn2.backgroundColor = UIColor.orange
            fromScriptBtn1.backgroundColor = UIColor.lightGray
            toScriptBtn1.backgroundColor = UIColor.lightGray
            toScriptBtn2.backgroundColor = UIColor.lightGray
            fromLangScript = (fromScriptBtn2.titleLabel?.text)!
        }
    }
    
    
    @IBAction func toScriptBtn1Pressed(_ sender: Any) {
        
        if fromScriptBtn2.backgroundColor != UIColor.orange {
            toScriptBtn1.backgroundColor = UIColor.orange
            toScriptBtn2.backgroundColor = UIColor.lightGray
            toLangScript = (toScriptBtn1.titleLabel?.text)!
        }

    }
    
    
    @IBAction func toScriptBtn2Pressed(_ sender: Any) {
        
        if fromScriptBtn2.backgroundColor != UIColor.orange {
            if toScriptBtn2.titleLabel?.text != "--" {
                toScriptBtn2.backgroundColor = UIColor.orange
                toScriptBtn1.backgroundColor = UIColor.lightGray
                toLangScript = (toScriptBtn2.titleLabel?.text)!
            }
        }

    }
    
    
    @IBAction func toScriptBtn3Pressed(_ sender: Any) {
        if fromScriptBtn1.backgroundColor != UIColor.orange {
            if toScriptBtn3.titleLabel?.text != "--" {
                toScriptBtn3.backgroundColor = UIColor.orange
                toScriptBtn4.backgroundColor = UIColor.lightGray
                toLangScript = (toScriptBtn3.titleLabel?.text)!
            }
        }
    }
    
    
    @IBAction func toScriptBtn4Pressed(_ sender: Any) {
        
        if fromScriptBtn1.backgroundColor != UIColor.orange {
            if toScriptBtn2.titleLabel?.text != "--" {
                toScriptBtn4.backgroundColor = UIColor.orange
                toScriptBtn3.backgroundColor = UIColor.lightGray
                toLangScript = (toScriptBtn4.titleLabel?.text)!
            }
        }
    }
    
    
    /* curl -X POST "https://api.cognitive.microsofttranslator.com/transliterate?api-version=3.0&language=ja&fromScript=Jpan&toScript=Latn" -H "X-ClientTraceId: 875030C7-5380-40B8-8A03-63DACCF69C11" -H "Ocp-Apim-Subscription-Key: <client-secret>" -H "Content-Type: application/json" -d @request.txt
    */
    @IBAction func transliterateBtnWasPressed(_ sender: Any) {
        
        var pickerSelection = Int()
        pickerSelection = languageName.selectedRow(inComponent: 0)
        languageCode = transliterateLangData[pickerSelection].langCode
        
        textToTransliterate.resignFirstResponder()
        let text2Transliterate = textToTransliterate.text

        // https://api.cognitive.microsofttranslator.com/transliterate?api-version=3.0
        
        let apiURL = "https://api.cognitive.microsofttranslator.com/transliterate?api-version=3.0&fromscript=" + fromLangScript + "&language=" + languageCode + "&toscript=" + toLangScript
        
        var encodeTextSingle = encodeText()
        var toTransliterate = [encodeText]()
        
        encodeTextSingle.text = text2Transliterate!
        toTransliterate.append(encodeTextSingle)
        print("struct to transliterate ", toTransliterate)
        
        let jsonToTransliterate = try? jsonEncoder.encode(toTransliterate)
        
        let url = URL(string: apiURL)
        var request = URLRequest(url: url!)
        print ("URL:", apiURL)
         
        request.httpMethod = "POST"
    	request.httpBody = jsonToTransliterate
        
        request.addValue(azureKey, forHTTPHeaderField: "Ocp-Apim-Subscription-Key")
        request.addValue(azureRegion, forHTTPHeaderField: "Ocp-Apim-Subscription-Region")
        request.addValue(contentType, forHTTPHeaderField: "Content-Type")
        request.addValue(traceID, forHTTPHeaderField: "X-ClientTraceID")
        request.addValue(host, forHTTPHeaderField: "Host")
        
        print ("Headers:", request.allHTTPHeaderFields!)
              
        let str = String(decoding: request.httpBody!, as: UTF8.self)
        print (str)
        
        let config = URLSessionConfiguration.default
        let session =  URLSession(configuration: config)
        
        let task = session.dataTask(with: request) { (responseData, response, responseError) in
            
            if responseError != nil {
                print("this is the error ", responseError!)
                
                let alert = UIAlertController(title: "Could not connect to service", message: "Please check your network connection and try again", preferredStyle: .actionSheet)
                
                alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                
                self.present(alert, animated: true)
            }
            
            self.parseTransliterationJson(jsonData: responseData!)
        }
        task.resume()
    }

    
    func getLanguages() {
        
        // https://api.cognitive.microsofttranslator.com -- TODO FIX URL to API Specs
        let sampleDataAddress = "https://dev.microsofttranslator.com/languages?api-version=3.0&scope=transliteration" //transliteration
        let url = URL(string: sampleDataAddress)!
        let jsonData = try! Data(contentsOf: url)
        let jsonDecoder = JSONDecoder()
        
        let languages = try? jsonDecoder.decode(Transliteration.self, from: jsonData)
        
        for language in (languages?.transliteration.values)! {
            
            transliterateLangDataEach.langName = language.name
            transliterateLangDataEach.langNativeName = language.nativeName
            print("number of scriptLangDetails structs", language.scripts.count)
            
            let countInScriptsArray = language.scripts.count
            
            for index1 in 0...countInScriptsArray - 1 {
                
                scriptLangDetailsSingle.code = language.scripts[index1].code
                scriptLangDetailsSingle.name = language.scripts[index1].name
                scriptLangDetailsSingle.nativeName = language.scripts[index1].nativeName
                scriptLangDetailsSingle.dir = language.scripts[index1].dir
                
                let countInToScriptsArray = language.scripts[index1].toScripts.count
                var counter = 0
                while counter < countInToScriptsArray {
                    toScriptDetails.code = language.scripts[index1].toScripts[counter].code
                    toScriptDetails.name = language.scripts[index1].toScripts[counter].name
                    toScriptDetails.nativeName = language.scripts[index1].toScripts[counter].nativeName
                    toScriptDetails.dir = language.scripts[index1].toScripts[counter].dir
                    print(language.scripts[index1].toScripts[counter].code)
                    counter += 1
                    scriptLangDetailsSingle.toScripts.append(toScriptDetails)
                }
                
                transliterateLangDataEach.langScriptData.append(scriptLangDetailsSingle)
                scriptLangDetailsSingle.toScripts.removeAll()
            }
            
            transliterateLangData.append(transliterateLangDataEach)
            transliterateLangDataEach.langScriptData.removeAll()
            
        }
        
        //*****Get lang code(keyvalue) into the struct array
        let countOfLanguages = languages?.transliteration.count
        var counter = 0
        
        for languageKey in languages!.transliteration.keys {
            
            if counter < countOfLanguages! {
                transliterateLangData[counter].langCode = languageKey
                counter += 1
            }
        }
        //*****end get key
        transliterateLangDataEach.langName = "--Select--"
        transliterateLangData.insert(transliterateLangDataEach, at: 0)

    }

    
    func parseTransliterationJson(jsonData: Data) {
        
        //*****Transliteration returned data*****

        struct TransliteratedStrings: Codable {
            var text: String
            var script: String
        }
        
        let transliteration = try? self.jsonDecoder.decode(Array<TransliteratedStrings>.self, from: jsonData)
        
        var numberOfTransliterations = Int()
        
        if transliteration?.count == nil {
            print("zero items returned")
            return
        } else {
            numberOfTransliterations = transliteration!.count - 1
        }
        
        print(transliteration!.count)

        //Put response on main thread to update UI
        DispatchQueue.main.async {
            self.transliteratedText.text = transliteration![numberOfTransliterations].text
        }
    }
    
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        
        let rowCount = transliterateLangData.count
        
        return rowCount
    }
    
    
    func pickerView(_ pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {
        var rowContent = String()
        
        rowContent = transliterateLangData[row].langName
        
        
        let attributedString = NSAttributedString(string: rowContent, 
        	attributes: [NSAttributedString.Key.foregroundColor: UIColor.black])
        
        return attributedString
    }

    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        let rowNumber = row
        
        fromScriptBtn1.setTitle("--", for: .normal)
        fromScriptBtn2.setTitle("--", for: .normal)
        toScriptBtn1.setTitle("--", for: .normal)
        toScriptBtn2.setTitle("--", for: .normal)
        toScriptBtn3.setTitle("--", for: .normal)
        toScriptBtn4.setTitle("--", for: .normal)
        
        fromScriptBtn1.backgroundColor = UIColor.lightGray
        fromScriptBtn2.backgroundColor = UIColor.lightGray
        toScriptBtn1.backgroundColor = UIColor.lightGray
        toScriptBtn2.backgroundColor = UIColor.lightGray
        toScriptBtn3.backgroundColor = UIColor.lightGray
        toScriptBtn4.backgroundColor = UIColor.lightGray
        
        var scriptsCounter = 1
        for scripts in transliterateLangData[rowNumber].langScriptData {
            print("from scripts", scripts.code)

            if scriptsCounter == 1 {
                fromScriptBtn1.setTitle(scripts.code, for: .normal)
                toScriptBtn1.setTitle(scripts.toScripts[0].code, for: .normal)
                if scripts.toScripts.count > 1 {
                    toScriptBtn2.setTitle(scripts.toScripts[1].code, for: .normal)
                }
            }
            
            if scriptsCounter == 2 {
                fromScriptBtn2.setTitle(scripts.code, for: .normal)
                toScriptBtn3.setTitle(scripts.toScripts[0].code, for: .normal)
                if scripts.toScripts.count > 1 {
                    toScriptBtn4.setTitle(scripts.toScripts[1].code, for: .normal)
                }
            }
            scriptsCounter += 1
            
        }
    }
}


extension TransliterationUIDel: UITextViewDelegate {
    
    //this clears the text view
    func textViewDidBeginEditing(_ textView: UITextView) {
        textToTransliterate.text = ""
    }
}










