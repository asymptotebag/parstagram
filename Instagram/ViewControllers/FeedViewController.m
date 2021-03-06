//
//  FeedViewController.m
//  Instagram
//
//  Created by Emily Jiang on 7/6/21.
//

#import "FeedViewController.h"
#import "LoginViewController.h"
#import "DetailsViewController.h"
#import "AppDelegate.h"
#import "SceneDelegate.h"
#import <Parse/Parse.h>
#import <QuartzCore/QuartzCore.h>
#import <MBProgressHUD/MBProgressHUD.h>
#import "PostCell.h"
#import "Post.h"

@interface FeedViewController () <UITableViewDataSource, UITableViewDelegate>
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, strong) UIRefreshControl *refreshControl;
@property (strong, nonatomic) NSArray *posts;
@property (nonatomic) BOOL loadedOnce;
@end

@implementation FeedViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.loadedOnce = false;
    [self setupView];
    [self fetchPosts];
}

- (void)setupView {
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(fetchPosts) forControlEvents:UIControlEventValueChanged];
    [self.tableView insertSubview:self.refreshControl atIndex:0];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.posts.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    PostCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"PostCell" forIndexPath:indexPath];
    Post *post = self.posts[indexPath.row];
    cell.post = post;
    return cell;
}

- (void)fetchPosts { // get feed
    if (!self.loadedOnce) { // first time loading
        [MBProgressHUD showHUDAddedTo:self.view animated:true];
    }
    
    // construct PFQuery
    PFQuery *postQuery = [Post query];
    [postQuery orderByDescending:@"createdAt"];
    [postQuery includeKey:@"author"];
    [postQuery includeKey:@"createdAt"];
    postQuery.limit = 20;

    // fetch data asynchronously
    [postQuery findObjectsInBackgroundWithBlock:^(NSArray<Post *> * _Nullable posts, NSError * _Nullable error) {
        if (posts) {
            self.posts = posts;
            [self.tableView reloadData];
            [self.refreshControl endRefreshing];
            [MBProgressHUD hideHUDForView:self.view animated:true];
            self.loadedOnce = true;
        }
        else {
            NSLog(@"Error fetching posts: %@", error.localizedDescription);
        }
    }];
}

- (IBAction)onLogout:(id)sender {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Logout Confirmation" message:@"Are you sure you want to log out?" preferredStyle:UIAlertControllerStyleActionSheet];
    UIAlertAction *logoutAction = [UIAlertAction actionWithTitle:@"Logout" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
//        [self dismissViewControllerAnimated:YES completion:^{}];
        
        [PFUser logOutInBackgroundWithBlock:^(NSError * _Nullable error) {
            if (error) {
                NSLog(@"Error: %@", error.localizedDescription);
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Logout Error" message:error.localizedDescription preferredStyle:UIAlertControllerStyleAlert];
                UIAlertAction *dismissAction = [UIAlertAction actionWithTitle:@"Dismiss" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {}];
                [alert addAction:dismissAction];
                [self presentViewController:alert animated:YES completion:^{}];
            } else {
                SceneDelegate *sceneDelegate = (SceneDelegate *)self.view.window.windowScene.delegate;
                UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
                LoginViewController *loginController = [storyboard instantiateViewControllerWithIdentifier:@"LoginViewController"];
                sceneDelegate.window.rootViewController = loginController;
            }
        }];
    }];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {}];
    [alert addAction:logoutAction];
    [alert addAction:cancelAction];
    [self presentViewController:alert animated:YES completion:^{}];
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    NSString *segId = [segue identifier];
    if ([segId isEqualToString:@"details"]) {
        UITableViewCell *tappedCell = sender;
        NSIndexPath *indexPath = [self.tableView indexPathForCell:tappedCell];
        Post *post = self.posts[indexPath.row];
        DetailsViewController *detailsVC = [segue destinationViewController];
        detailsVC.post = post;
    } else {
        NSLog(@"Segue not recognized");
    }
}

@end
