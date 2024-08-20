//
//  ViewController.swift
//  Todoey
//
//  Created by Philipp Muellauer on 02/12/2019.
//  Copyright © 2019 App Brewery. All rights reserved.
//

import UIKit
import CoreData

class TodoListViewController: UITableViewController {
    
    var items = [Item] ()
    
    var selectedCategory : Category? {
        didSet{
            loadItems()
        }
    }
    
    //let defaults = UserDefaults() -> we wont use it because it saves limited types of data
    
    let dataFilePath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
    
    //in order to reach appdelegate functions
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    @IBOutlet weak var searchBar: UISearchBar!

    override func viewDidLoad() {
        super.viewDidLoad()
        print(FileManager.default.urls(for: .documentDirectory, in: .userDomainMask))
        
        searchBar.placeholder = "Search Item"
        //updating the array if the app is terminated
//        if let item = defaults.array(forKey: "ToDoListArray") as? [String] {
//            items = item
//        }
        
        // Do any additional setup after loading the view. -> v1
        //loadItems()
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ToDoItemCell", for: indexPath)
        
        let item = items[indexPath.row]
        
        cell.textLabel?.text = item.title
        
        cell.accessoryType = item.done ? .checkmark : .none
        
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print(items[indexPath.row]) //prints the data in console
    
        //adds checkmarks to the row
        //tableView.cellForRow(at: indexPath)?.accessoryType = .checkmark
        
        //set value ->
        //items[indexPath.row].setValue("text", forKey: "title")
        
        //delete -- the order should be like this. otherwise there will be some unexpected actions
        context.delete(items[indexPath.row]) //removes from db
        items.remove(at: indexPath.row) // removes from screen
        
        items[indexPath.row].done = !items[indexPath.row].done

        saveItems()
        
        tableView.deselectRow(at: indexPath, animated: true)
    
    }
    
    @IBAction func addButtonPressed(_ sender: UIBarButtonItem) {
        
        var textField = UITextField()
        
        let alert = UIAlertController(title: "Add New TodoeyItem", message: "", preferredStyle: .alert)
        
        let action =  UIAlertAction(title: "Add Item", style: .destructive) {
            (action) in
            //what will happen once the user clicks the Add Item button on UIAlert
            
            //self.items.append(textField.text!) -> v1
            //self.defaults.set(self.items, forKey: "ToDoListArray") -> v1
            
            let newItem = Item(context: self.context)
            newItem.title = textField.text!
            newItem.done = false
            newItem.parentCategory = self.selectedCategory
            self.items.append(newItem)
            
            //reloads the changed array -> v1
            //self.tableView.reloadData()
            
            self.saveItems()
            
        }
        
        alert.addTextField{ (alertTextField) in 
            alertTextField.placeholder = "Create new Item"
            alertTextField.accessibilityIdentifier = "createNewItem"
            textField = alertTextField
        }
        
        alert.addAction(action)
        
        present(alert, animated: true, completion: nil)
    }
    
    func saveItems() {
        
        do {
            try context.save()
        } catch {
            print("Error saving -> \(error)")

        }
        self.tableView.reloadData()
    }
    
    //fetchibg the from DB
    //external value - with
    //internal value - request
    //default value - Item.fetchRequest()
    func loadItems(with request: NSFetchRequest<Item> = Item.fetchRequest(), predicate: NSPredicate? = nil) {
            
            let categoryPredicate = NSPredicate(format: "parentCategory.name MATCHES %@", selectedCategory!.name!)
            
            if let addtionalPredicate = predicate {
                request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [categoryPredicate, addtionalPredicate])
            } else {
                request.predicate = categoryPredicate
            }

            
            do {
                items = try context.fetch(request)
            } catch {
                print("Error fetching data from context \(error)")
            }
            
            tableView.reloadData()
            
        }
    
}

//MARK: - Search bar methods
extension TodoListViewController: UISearchBarDelegate {
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        let request : NSFetchRequest<Item> = Item.fetchRequest()
        
        request.predicate = NSPredicate(format: "title CONTAINS[cd] %@", searchBar.text!)
        
        request.sortDescriptors = [NSSortDescriptor(key: "title", ascending: true)]
        
        loadItems(with: request)
    }
    
    //reloads the list after remove the search item
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        
        if searchBar.text?.count == 0 {
            loadItems()
            
            //kyboard and curse disappears
            DispatchQueue.main.async {
                searchBar.resignFirstResponder()
            }
            
        }
    }
}
