//
//  ViewController.swift
//  JobTrack
//
//  Created by Arjun Dureja on 2020-07-26.
//  Copyright © 2020 Arjun Dureja. All rights reserved.
//

import UIKit

class HomeViewController: UIViewController, UIPopoverPresentationControllerDelegate {

    // MARK: - Properties

    // Core Data context
    private let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    let headerVC = HeaderViewController()
    let filterVC = FilterViewController()
    let jobsVC = JobsViewController()
    var allCompanies = [Company]() {
        didSet {
            jobsVC.companies = allCompanies
        }
    }
    let statusPickerView = UIPickerView()
    let generator = UIImpactFeedbackGenerator(style: .light)
    let statusPickerData = [
        "All",
        ApplicationStatus.applied.rawValue.capitalized,
        ApplicationStatus.phoneScreen.rawValue.capitalized,
        ApplicationStatus.onSite.rawValue.capitalized,
        ApplicationStatus.offer.rawValue.capitalized,
        ApplicationStatus.rejected.rawValue.capitalized
    ]

    let statusFieldColors: [UIColor] = [
        .semanticFilterBorder,
        .appliedBackground,
        .phoneScreenBackground,
        .onSiteBackground,
        .offerBackground,
        .rejectedBackground
    ]

    override func viewDidLoad() {
        super.viewDidLoad()
        addHeaderVC()
        addFilterVC()
        addJobsVC()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // Fetch companies from core data and sort by date
        do {
            self.allCompanies = try context.fetch(Company.fetchRequest())
            self.sortAllCompaniesByDate()
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
    }

    func sortAllCompaniesByDate() {
        allCompanies = allCompanies.sorted {
            $0.dateAdded > $1.dateAdded
        }
    }

    func saveCoreDateContext() {
        do {
            try self.context.save()
        } catch let error as NSError {
            print(error)
        }
    }

    // Add header VC as child
    func addHeaderVC() {
        addChild(headerVC)
        view.addSubview(headerVC.view)
        headerVC.didMove(toParent: self)
        setHeaderVCConstraints()
        headerVC.addButton.addTarget(self, action: #selector(addTapped), for: .touchUpInside)
    }

    func setHeaderVCConstraints() {
        headerVC.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            headerVC.view.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            headerVC.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerVC.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerVC.view.heightAnchor.constraint(equalToConstant: 40)
        ])
    }

    // Add filter VC as chidl
    func addFilterVC() {
        addChild(filterVC)
        view.addSubview(filterVC.view)
        filterVC.didMove(toParent: self)
        setFilterVCConstraints()
        filterVC.searchBar.delegate = self
        for button in filterVC.filterButtons {
            button.addTarget(self, action: #selector(filterButtonTapped(_:)), for: .touchUpInside)
        }

        setupStatusPicker()
    }

    // Picker for filter VC
    func setupStatusPicker() {
        let toolBar = UIToolbar(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 35))
        toolBar.barStyle = UIBarStyle.default
        toolBar.isTranslucent = true
        toolBar.sizeToFit()
        let doneButton = UIBarButtonItem(
            title: "Done",
            style: UIBarButtonItem.Style.done,
            target: self,
            action: #selector(doneTapped)
        )

        doneButton.tintColor = .tappedButton
        let space = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        toolBar.setItems([space, doneButton], animated: false)
        toolBar.isUserInteractionEnabled = true
        statusPickerView.delegate = self
        statusPickerView.dataSource = self
        filterVC.statusField.inputAccessoryView = toolBar
        filterVC.statusField.inputView = statusPickerView
    }

    // Toolbar done button tapped in filter VC
    @objc func doneTapped() {
        self.filterVC.statusField.resignFirstResponder()
    }

    func setFilterVCConstraints() {
        filterVC.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            filterVC.view.topAnchor.constraint(equalTo: headerVC.view.bottomAnchor),
            filterVC.view.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            filterVC.view.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            filterVC.view.heightAnchor.constraint(equalToConstant: 160)
        ])
    }

    // Add jobs VC as child
    func addJobsVC() {
        addChild(jobsVC)
        view.addSubview(jobsVC.view)
        jobsVC.didMove(toParent: self)
        setJobsVCConstraints()
        jobsVC.delegate = self
        jobsVC.deleteDelegate = self
        jobsVC.editDelegate = self
    }

    func setJobsVCConstraints() {
        jobsVC.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            jobsVC.view.topAnchor.constraint(equalTo: filterVC.view.bottomAnchor),
            jobsVC.view.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            jobsVC.view.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            jobsVC.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
}

// MARK: - Add Job Delegate
extension HomeViewController: AddJobDelegate {

    // Function called when the top right Add Button is tapped
    @objc func addTapped() {
        let vc = AddJobViewController()
        vc.jobDelegate = self

        if filterVC.searchBar.isFirstResponder {
            filterVC.searchBar.resignFirstResponder()
            filterVC.searchBar.text = nil
            filterVC.dateButton.sendActions(for: .touchUpInside)
        }

        present(vc, animated: true)
    }

    // Function called when the Add Job button is tapped
    func addButtonTapped(
        companyName: String,
        jobPosition: String,
        dateAdded: Date,
        applicationStatus: ApplicationStatus
    ) {
        let company = Company(context: self.context)
        company.companyName = companyName
        company.jobPosition = jobPosition
        company.applicationStatus = applicationStatus
        company.isFavorite = false
        company.dateAdded = dateAdded

        allCompanies.append(company)
        sortAllCompaniesByDate()
        filterVC.dateButton.sendActions(for: .touchUpInside)

        let success = UINotificationFeedbackGenerator()
        success.notificationOccurred(.success)

        saveCoreDateContext()
    }

    // Unused delegate function - used in Jobs VC
    func saveButtonTapped(company: Company) {
        return
    }
}

// MARK: - Search Bar Delegate
extension HomeViewController: UISearchBarDelegate {

    // When user taps search bar
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        generator.impactOccurred()
        for button in filterVC.filterButtons {
            button.setTitleColor(.semanticFilterText, for: .normal)
            button.backgroundColor = .systemBackground
            button.isSelected = false
        }

        if filterVC.statusFieldLabel.text != "ALL" {
            statusPickerView.selectRow(0, inComponent: 0, animated: true)
            filterVC.statusFieldLabel.text = "ALL"
            filterVC.statusFieldLabel.textColor = .semanticFilterText
            filterVC.statusField.layer.borderColor = UIColor.semanticFilterBorder.cgColor
            filterVC.statusFieldDownArrow.textColor = filterVC.statusFieldLabel.textColor
        }

        if searchBar.text == "" {
            jobsVC.companies = allCompanies
        }
    }

    // When user taps search button in keyboard
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()

        if searchBar.text == "" {
            filterVC.dateButton.sendActions(for: .touchUpInside)
        }

    }

    // Search for results as user types
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        jobsVC.companies = allCompanies.filter {
            $0.companyName.lowercased().hasPrefix(searchText.lowercased())
        }
    }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }

}

// MARK: - Filter Buttons Tapped, Picker View Delegate
extension HomeViewController: UIPickerViewDelegate, UIPickerViewDataSource {

    // When user taps one of the filter buttons
    @objc func filterButtonTapped(_ sender: UIButton) {
        for button in filterVC.filterButtons {
            button.setTitleColor(.semanticFilterText, for: .normal)
            button.backgroundColor = .systemBackground
            if !sender.isSelected {
                button.isSelected = false
            }
        }

        if filterVC.statusFieldLabel.text != "ALL" ||
            filterVC.searchBar.isFirstResponder ||
            statusPickerView.isFirstResponder ||
            filterVC.searchBar.text != nil {
            statusPickerView.selectRow(0, inComponent: 0, animated: true)
            filterVC.statusFieldLabel.text = "ALL"
            filterVC.statusFieldLabel.textColor = .semanticFilterText
            filterVC.statusField.layer.borderColor = UIColor.semanticFilterBorder.cgColor
            filterVC.statusFieldDownArrow.textColor = filterVC.statusFieldLabel.textColor
            filterVC.searchBar.resignFirstResponder()
            filterVC.statusField.resignFirstResponder()
            filterVC.searchBar.text = nil
        }

        generator.impactOccurred()
        sender.setTitleColor(.white, for: .normal)
        sender.backgroundColor = .tappedButton
        sender.isSelected = true

        // Sort based on which button user tapped
        if sender.titleLabel?.text == FilterStatus.byDate() {
            jobsVC.companies = allCompanies.sorted {
                $0.dateAdded > $1.dateAdded
            }
        } else if sender.titleLabel?.text == FilterStatus.byStatus() {
            jobsVC.companies = allCompanies.sorted {
                $0.applicationStatus < $1.applicationStatus
            }
        } else if sender.titleLabel?.text == FilterStatus.aToZ() {
            jobsVC.companies = allCompanies.sorted {
                $0.companyName.lowercased() < $1.companyName.lowercased()
            }
        } else if sender.titleLabel?.text == FilterStatus.favorites() {
            jobsVC.companies = allCompanies.filter {
                $0.isFavorite
            }
        }

        jobsVC.jobsCollectionView.setContentOffset(CGPoint(x: 0, y: 0), animated: true)
    }

    // User selected filter by status picker
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        filterVC.searchBar.resignFirstResponder()
        filterVC.searchBar.text = nil

        filterVC.statusFieldLabel.text = statusPickerData[row].uppercased()
        filterVC.statusField.layer.borderColor = statusFieldColors[row].cgColor
        if row == 0 {
            filterVC.statusFieldLabel.textColor = .semanticFilterText
            filterVC.dateButton.sendActions(for: .touchUpInside)
        } else {
            filterVC.statusFieldLabel.textColor = statusFieldColors[row]
            for button in filterVC.filterButtons {
                button.setTitleColor(.semanticFilterText, for: .normal)
                button.backgroundColor = .systemBackground
                button.isSelected = false
            }
        }

        filterVC.statusFieldDownArrow.textColor = filterVC.statusFieldLabel.textColor

        // Sort based on which status user selected
        switch row {
        case 0:
            jobsVC.companies = allCompanies
        case 1:
            jobsVC.companies = allCompanies.filter {
                $0.applicationStatus == .applied
            }
        case 2:
            jobsVC.companies = allCompanies.filter {
                $0.applicationStatus == .phoneScreen
            }
        case 3:
            jobsVC.companies = allCompanies.filter {
                $0.applicationStatus == .onSite
            }
        case 4:
            jobsVC.companies = allCompanies.filter {
                $0.applicationStatus == .offer
            }
        case 5:
            jobsVC.companies = allCompanies.filter {
                $0.applicationStatus == .rejected
            }
        default:
            break
        }
    }

    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return statusPickerData.count
    }

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return statusPickerData[row]
    }

}

// MARK: - Favorite Button Tapped
extension HomeViewController: FavoriteButton {

    // When user taps the favorite button
    func favoriteButtonTapped(at indexPath: IndexPath) {
        self.jobsVC.companies[indexPath.item].isFavorite = true
        for i in 0..<allCompanies.count
        where allCompanies[i].dateAdded == jobsVC.companies[indexPath.item].dateAdded {
            allCompanies[i].isFavorite = true
            break
        }
    }

    // When user taps the favorite button to un-favorite
    func favoriteButtonUnTapped(at indexPath: IndexPath) {
        self.jobsVC.companies[indexPath.item].isFavorite = false
        for i in 0..<allCompanies.count
        where allCompanies[i].dateAdded == jobsVC.companies[indexPath.item].dateAdded {
            allCompanies[i].isFavorite = false
            break
        }
    }

}

// MARK: - Delete or Edit Button Delegate
extension HomeViewController: DeleteButtonDelegate, EditJobDelegate {

    // User deleted a job
    func deleteTapped(at company: Company) {
        let success = UINotificationFeedbackGenerator()
        success.notificationOccurred(.success)

        // Remove locally
        for i in 0..<allCompanies.count where allCompanies[i].dateAdded == company.dateAdded {
            allCompanies.remove(at: i)
            break
        }

        self.context.delete(company)

        // Save core data context
        saveCoreDateContext()
    }

    // User finished editing a job
    func jobEdited(company: Company) {
        let success = UINotificationFeedbackGenerator()
        success.notificationOccurred(.success)
        for i in 0..<allCompanies.count where allCompanies[i].dateAdded == company.dateAdded {
            allCompanies[i] = company
            break
        }
        sortAllCompaniesByDate()
        saveCoreDateContext()
    }
}
