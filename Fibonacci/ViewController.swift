//
//  ViewController.swift
//  Fibonacci
//
//  Created by Alex Sobolevski on 4/4/17.
//  Copyright © 2017 Alex Sobolevski. All rights reserved.
//

import UIKit
import BigInt


class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate {
    
    //ui outlets
    @IBOutlet weak var fibonacciTableView: UITableView!
    @IBOutlet weak var searchFibonacciBar: UISearchBar!
    @IBOutlet weak var loadIndicator: UIActivityIndicatorView!
    
    //internal properties
    
    private var searchCriteria: Int?
    private var countRow = 20
    private var loadMoreStatus = false
    private var data: [BigUInt] = [0]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        var n = 1
        while (n < 21) {
            data.append(fibonacci(n: BigUInt(n)))
            n += 1
        }
        fibonacciTableView.dataSource = self
        fibonacciTableView.delegate = self
        searchFibonacciBar.delegate = self
        
        loadIndicator.isHidden = true
        
        fibonacciTableView.rowHeight = UITableViewAutomaticDimension
        fibonacciTableView.estimatedRowHeight = 40
        
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(gestureRecognizer)
    }
    
    func dismissKeyboard() {
        searchFibonacciBar.resignFirstResponder()
    }
    
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return countRow
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: "fibonacci cell")
        
        if cell == nil {
            cell = UITableViewCell.init(style: UITableViewCellStyle.value1, reuseIdentifier: "fibonacci cell")
        }
        
        cell?.textLabel?.numberOfLines = 0
        cell?.textLabel?.lineBreakMode = .byWordWrapping

        cell?.textLabel?.text = "FIB \(indexPath.row): \(String(describing: data[indexPath.row]))"
        return cell!
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let currentOffset = scrollView.contentOffset.y
        let maximumOffset = scrollView.contentSize.height - scrollView.frame.size.height
        let deltaOffset = maximumOffset - currentOffset
        
        if deltaOffset <= 0 {
            loadMore()
        }
    }
    
    func loadMore() {
        if ( !loadMoreStatus ) {
            self.loadMoreStatus = true
            loadMoreBegin(loadMoreEnd: {(x:Int) -> () in
                self.fibonacciTableView.reloadData()
                self.loadMoreStatus = false
            })
        }
    }
    
    func loadMoreBegin(loadMoreEnd:@escaping (Int) -> ()) {
        DispatchQueue.global(qos: .userInitiated).async {
            var count: BigUInt = 0
            while (count < 20) {
                self.data.append(self.fibonacci(n: BigUInt(self.data.count)))
                count += 1
            }
            
            self.countRow += 20
            
            DispatchQueue.main.async {
                loadMoreEnd(0)
            }
        }
    }
    
    func fibonacci(n: BigUInt) -> BigUInt {
        var numberId = n
        if numberId < 0 {
            //
        }
        if numberId <= 1 {
            return numberId
        }
        
        var result: [[BigUInt]] = [[1, 0], [0, 1]]
        var fiboNum: [[BigUInt]] = [[1, 1], [1, 0]]
        
        while numberId > 0 {
            if numberId%2 == 1 {
                result = multiplyMatrix(matr1: result, matr2: fiboNum)
            }
            numberId /= 2
            fiboNum = multiplyMatrix(matr1: fiboNum, matr2: fiboNum)
        }
        
        return result[1][0]
    }
    
    func multiplyMatrix(matr1 : [[BigUInt]], matr2 : [[BigUInt]]) -> [[BigUInt]] {
        let value1 = matr1[0][0] * matr2[0][0] + matr1[0][1] * matr2[1][0]
        let value2 = matr1[0][0] * matr2[0][1] + matr1[0][1] * matr2[1][1]
        let value3 = matr1[1][0] * matr2[0][0] + matr1[1][1] * matr2[0][1]
        let value4 = matr1[1][0] * matr2[0][1] + matr1[1][1] * matr2[1][1]
        
        let result: [[BigUInt]] = [[value1, value2], [value3, value4]]
        
        return result
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if let numberToFind = Int(searchText) {
            searchCriteria = (numberToFind + 1)
        }
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        if let searchCriteria = searchCriteria {
            if searchCriteria < data.count - 20 {
                fibonacciTableView.reloadData()
                let indexPath = IndexPath(row: searchCriteria - 1, section: 0)
                fibonacciTableView.scrollToRow(at: indexPath, at: .top, animated: true)
            } else {
                fibonacciTableView.reloadData()
                let indexPath = IndexPath(row: data.indices.last! - 1, section: 0)
                fibonacciTableView.scrollToRow(at: indexPath, at: .top, animated: true)
                loadIndicator.isHidden = false
                loadIndicator.startAnimating()
                DispatchQueue.global(qos: .userInitiated).async { [weak self] _ in
                    guard self != nil else { return }
                    while self!.countRow - 21 < searchCriteria {
                        self!.loadMore()
                    }
                    DispatchQueue.main.async { [weak self] _ in
                        guard self != nil else { return }
                        self!.fibonacciTableView.reloadData()
                        let indexPath = IndexPath(row: searchCriteria - 1, section: 0)
                        self!.fibonacciTableView.scrollToRow(at: indexPath, at: .top, animated: true)
                        self!.loadIndicator.stopAnimating()
                        self!.loadIndicator.isHidden = true
                    }
                }
            }
        }
    }
}

