//
//  SettingsViewController.swift
//  DAPathfinder
//
//  Created by Claude on 2026-01-05.
//  Copyright © 2026 Domenico. All rights reserved.
//

import UIKit

class SettingsViewController: UIViewController {

    @IBOutlet weak var populationSizeTextField: UITextField!
    @IBOutlet weak var mutationProbabilityTextField: UITextField!
    @IBOutlet weak var eliteSizeTextField: UITextField!
    @IBOutlet weak var updateButton: UIButton!
    @IBOutlet weak var resetButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Set up text field delegates for keyboard dismissal
        populationSizeTextField.delegate = self
        mutationProbabilityTextField.delegate = self
        eliteSizeTextField.delegate = self

        // Add toolbar with Done button to number pad keyboards
        addDoneButtonToKeyboard(for: populationSizeTextField)
        addDoneButtonToKeyboard(for: mutationProbabilityTextField)
        addDoneButtonToKeyboard(for: eliteSizeTextField)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadCurrentSettings()
    }

    private func loadCurrentSettings() {
        let settings = GeneticAlgorithmSettings.shared
        populationSizeTextField.text = "\(settings.populationSize)"
        mutationProbabilityTextField.text = "\(settings.mutationProbability)"
        eliteSizeTextField.text = "\(settings.eliteSize)"
    }

    private func addDoneButtonToKeyboard(for textField: UITextField) {
        let toolbar = UIToolbar()
        toolbar.sizeToFit()

        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismissKeyboard))

        toolbar.items = [flexSpace, doneButton]
        textField.inputAccessoryView = toolbar
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    @IBAction func updateSettings(_ sender: Any) {
        guard let populationSizeText = populationSizeTextField.text,
              let mutationProbabilityText = mutationProbabilityTextField.text,
              let eliteSizeText = eliteSizeTextField.text else {
            showError(message: "Please fill in all fields")
            return
        }

        guard let populationSize = Int(populationSizeText),
              let mutationProbability = Double(mutationProbabilityText),
              let eliteSize = Int(eliteSizeText) else {
            showError(message: "Please enter valid numeric values")
            return
        }

        do {
            try GeneticAlgorithmSettings.shared.updateSettings(
                populationSize: populationSize,
                mutationProbability: mutationProbability,
                eliteSize: eliteSize
            )

            // Show success feedback
            showSuccess(message: "Settings updated successfully")
            dismissKeyboard()
        } catch let error as GeneticAlgorithmSettings.ValidationError {
            showError(message: error.localizedDescription)
        } catch {
            showError(message: "An error occurred while updating settings")
        }
    }

    @IBAction func resetSettings(_ sender: Any) {
        GeneticAlgorithmSettings.shared.resetToDefaults()
        loadCurrentSettings()
        showSuccess(message: "Settings reset to defaults")
    }

    private func showError(message: String) {
        let alert = UIAlertController(title: "Invalid Settings", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }

    private func showSuccess(message: String) {
        let alert = UIAlertController(title: "Success", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
}

extension SettingsViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
