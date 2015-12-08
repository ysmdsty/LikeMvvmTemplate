import UIKit
import RxSwift
import RxCocoa
import SwiftyJSON

class RxSwiftDemoSecondViewController: UITableViewController {
    private var listViewModel: ListViewModel = ListViewModel()
    private var dataSource: [Variable<[ListCellViewModel]>]!

    var disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let refreshControl = UIRefreshControl()
        self.tableView.addSubview(refreshControl)
        refreshControl.addTarget(self, action: Selector("loadNextSet:"), forControlEvents: UIControlEvents.ValueChanged)
        dataSource = [listViewModel.repositoryCellViewModels]
        listViewModel.dataSetChaged = AnyObserver{[unowned self] _ in
            self.tableView.reloadData()
        }
        
        tableView.dataSource = self
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return dataSource.count
    }
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource[section].value.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("cell", forIndexPath: indexPath) as! RxSwiftDemoSecondCell
        let viewModel = dataSource[indexPath.section].value[indexPath.row]
        viewModel.name.bindTo(cell.nameLabel.rx_text).addDisposableTo(cell.disposeBag)
        viewModel.photo.bindTo(cell.avatarImageView.rx_image).addDisposableTo(cell.disposeBag)
        viewModel.fetchPhotoIfNeeded()
        return cell
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        listViewModel.fetchNextPageOfRepositories() {}
    }
    func loadNextSet(refreshControl: UIRefreshControl) {
        listViewModel.fetchNextPageOfRepositories() {refreshControl.endRefreshing()}
    }
}

class RxSwiftDemoSecondCell: UITableViewCell {
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var avatarImageView: UIImageView!
    
    var disposeBag = DisposeBag()
    
    override func prepareForReuse() {
        super.prepareForReuse()
        avatarImageView.image = nil
        
        disposeBag = DisposeBag()
    }
}

private class ListViewModel {
    var repositoryCellViewModels: Variable<[ListCellViewModel]> = Variable([])
    var dataSetChaged: AnyObserver<Bool>!
    private var apiURL: NSURL! {return NSURL(string: "https://api.github.com/repositories" + "?since=\(since)")}
    private var since = 0

    func fetchNextPageOfRepositories(completion: () -> Void) {
        Mock.dispatchAsyncGlobal {
            guard let data = NSData(contentsOfURL: self.apiURL) else {return}
            guard let jsonResult = JSON(data: data, options: .MutableLeaves, error: nil).array else {return}
            Mock.dispatchAsyncMain({
                var newRepos: [ListCellViewModel] = []
                for repo in jsonResult {
                    let id = repo["id"].intValue
                    let name = repo["name"].stringValue
                    let owner = repo["owner"].dictionary
                    let username = owner?["login"]?.stringValue ?? ""
                    let photoURL = owner?["avatar_url"]?.stringValue
                    self.since = max(self.since, id)
                    newRepos.append(ListCellViewModel(name: name, username: username, photoUrl: photoURL))
                }
                self.repositoryCellViewModels.value.insertContentsOf(newRepos.reverse(), at: 0)
                self.dataSetChaged.onNext(true)
                completion()
            })
        }
    }
}

private class ListCellViewModel {
    let name: Variable<String>
    let photo: Variable<UIImage?>
    let photoUrl: String?

    init(name: String, username: String, photoUrl: String?) {
        self.name = Variable(name)
        self.photo = Variable(nil) // initially no photo
        self.photoUrl = photoUrl
    }

    func fetchPhotoIfNeeded() {
        if self.photo.value != nil {return}
        guard let photoUrlStr = photoUrl else {return}
        guard let photoUrl = NSURL(string: photoUrlStr) else {return}
        
        NSURLSession.sharedSession()
            .downloadTaskWithURL(photoUrl) { [weak self] location, response, error in
                guard let location = location, data = NSData(contentsOfURL: location), image = UIImage(data: data) else {return}
                Mock.dispatchAsyncMain { self?.photo.value = image }
            }.resume()
    }
}