//
//  NewConversationsViewController.swift
//  chatapp
//
//  Created by Sanviraj Zahin Haque on 11/8/20.
//  Copyright © 2020 Sanviraj Zahin Haque. All rights reserved.
//

import UIKit
import JGProgressHUD

class NewConversationsViewController: UIViewController {
    
    private let spinner = JGProgressHUD(style: .dark)
    
    private var users = [[String : String]]()
    private var results = [[String : String]]()
    private var hasFetched = false
    private let searchBar : UISearchBar = {
        let searchBar = UISearchBar()
        
        searchBar.placeholder = "Search for users"
        return searchBar
    }()
    
    private let tableView : UITableView = {
       let table = UITableView()
        table.isHidden = true
        table.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        return table
    }()
    
    private let noResultsLabel : UILabel = {
        let label = UILabel()
        label.isHidden = true
        label.text = "No results"
        label.textAlignment = .center
        label.textColor = .green
        label.font = .systemFont(ofSize: 21, weight: .medium)
        return label
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(noResultsLabel)
        view.addSubview(tableView)
        
        tableView.delegate = self
        tableView.dataSource = self
        searchBar.delegate = self
        view.backgroundColor = .white
        
        navigationController?.navigationBar.topItem?.titleView = searchBar
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "cancel", style: .done, target: self, action: #selector(dismissSelf))

        searchBar.becomeFirstResponder()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.frame = view.bounds
        noResultsLabel.frame = CGRect(x: view.width/4, y: (view.height-200)/2, width: view.width/2, height: 100)
    }
    
    @objc private func dismissSelf(){
        dismiss(animated: true, completion: nil)
    }
    

    

}

extension NewConversationsViewController : UISearchBarDelegate{
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        
        
        guard let text = searchBar.text , !text.replacingOccurrences(of: " ", with: "").isEmpty else {
            return
        }
        
        searchBar.resignFirstResponder()
        
        results.removeAll()
        
        spinner.show(in: view)
        self.searchUsers(query: text)
        
    }
    
    func searchUsers(query : String){
        
        //check array for results
        
        if hasFetched{
            
            filterUsers(with: query)
        }
        
        else{
           
            //fetch + filter
            
            DatabaseManager.shared.getAllUsers(completion: {[weak self] result in
                
                switch result {
                case .success(let usersCollection):
                    self?.hasFetched = true
                    self?.users = usersCollection
                    self?.filterUsers(with: query)
                case .failure(let error):
                    print("failed to get user \(error)")
                }
                
            })
            
        }
        
        
        
        //update UI
        
        
        //show results
        
    }
    
    func filterUsers (with term : String){
        guard hasFetched else {
            return
        }
        self.spinner.dismiss()
        var results : [[String : String]] = self.users.filter({
            guard let name = $0["name"]?.lowercased() else{
                return false
            }
            return name.hasPrefix(term.lowercased())
        })
        
        self.results = results
        
        updateUI()
       
    }
    
    func updateUI(){
        if results.isEmpty{
            self.noResultsLabel.isHidden = false
            self.tableView.isHidden = true
        }
        else{
            self.noResultsLabel.isHidden = true
            self.tableView.isHidden = false
            self.tableView.reloadData()
        }
    }
}

extension NewConversationsViewController :  UITableViewDelegate,UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return results.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = results[indexPath.row]["name"]
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        //start convo here
    }
    
    
}
