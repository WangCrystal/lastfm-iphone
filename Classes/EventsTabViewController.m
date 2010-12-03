/* EventsViewController.m - Display various kinds of events for a user
 * 
 * Copyright 2010 Last.fm Ltd.
 *   - Primarily authored by Sam Steele <sam@last.fm>
 *
 * This file is part of MobileLastFM.
 *
 * MobileLastFM is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * MobileLastFM is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with MobileLastFM.  If not, see <http://www.gnu.org/licenses/>.
 */

#import "EventsTabViewController.h"
#import "EventDetailsViewController.h"
#import "UIViewController+NowPlayingButton.h"
#import "UITableViewCell+ProgressIndicator.h"
#import "MobileLastFMApplicationDelegate.h"
#include "version.h"
#import "NSString+URLEscaped.h"
#import <QuartzCore/QuartzCore.h>

UIImage *eventDateBGImage = nil;

@implementation MiniEventCell

@synthesize title, location, month, day;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)identifier {
	if (self = [super initWithStyle:style reuseIdentifier:identifier]) {
		
		if(!eventDateBGImage)
			eventDateBGImage = [[UIImage imageNamed:@"date.png"] retain];
		
		_datebg = [[UIImageView alloc] initWithImage:eventDateBGImage];
		_datebg.contentMode = UIViewContentModeScaleAspectFill;
		_datebg.clipsToBounds = YES;
		[_datebg.layer setBorderColor: [[UIColor blackColor] CGColor]];
		[_datebg.layer setBorderWidth: 1.0];
		[self.contentView addSubview:_datebg];
		
		month = [[UILabel alloc] init];
		month.textColor = [UIColor whiteColor];
		month.backgroundColor = [UIColor clearColor];
		month.textAlignment = UITextAlignmentCenter;
		month.font = [UIFont boldSystemFontOfSize:14];
		month.shadowColor = [UIColor blackColor];
		month.shadowOffset = CGSizeMake(0.0, 1.0);
		[_datebg addSubview: month];
		
		day = [[UILabel alloc] init];
		day.textColor = [UIColor blackColor];
		day.backgroundColor = [UIColor clearColor];
		day.textAlignment = UITextAlignmentCenter;
		day.font = [UIFont boldSystemFontOfSize:28];
		[_datebg addSubview: day];
		
		title = [[UILabel alloc] init];
		title.textColor = [UIColor blackColor];
		title.highlightedTextColor = [UIColor whiteColor];
		title.backgroundColor = [UIColor whiteColor];
		title.font = [UIFont boldSystemFontOfSize:16];
		title.opaque = YES;
		[self.contentView addSubview:title];
		
		location = [[UILabel alloc] init];
		location.textColor = [UIColor grayColor];
		location.highlightedTextColor = [UIColor whiteColor];
		location.backgroundColor = [UIColor whiteColor];
		location.font = [UIFont systemFontOfSize:14];
		location.clipsToBounds = YES;
		location.opaque = YES;
		[self.contentView addSubview:location];
		
		self.selectionStyle = UITableViewCellSelectionStyleBlue;
	}
	return self;
}
- (void)layoutSubviews {
	[super layoutSubviews];
	
	CGRect frame = [self.contentView bounds];
	if(self.accessoryView != nil)
		frame.size.width = frame.size.width - [self.accessoryView bounds].size.width;
	
	_datebg.frame = CGRectMake(frame.origin.x+8, frame.origin.y+8, 40, 48);
	month.frame = CGRectMake(0,2,40,10);
	day.frame = CGRectMake(0,12,40,38);
	
	title.frame = CGRectMake(_datebg.frame.origin.x + _datebg.frame.size.width + 6, frame.origin.y + 4, frame.size.width - _datebg.frame.size.width - 12, 22);
	location.frame = CGRectMake(_datebg.frame.origin.x + _datebg.frame.size.width + 6, frame.origin.y + 24, frame.size.width - _datebg.frame.size.width - 12, 
																[location.text sizeWithFont:location.font constrainedToSize:CGSizeMake(frame.size.width - _datebg.frame.size.width - 12, frame.size.height - 24) lineBreakMode:location.lineBreakMode].height);
}
- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
	[super setSelected:selected animated:animated];
	if(self.selectionStyle != UITableViewCellSelectionStyleNone) {
		title.highlighted = selected;
		location.highlighted = selected;
	}
}
- (void)dealloc {
	[title release];
	[location release];
	[day release];
	[month release];
	[_datebg release];
	[super dealloc];
}
@end

@implementation EventsTabViewController
- (id)initWithUsername:(NSString *)username {
	if (self = [super initWithStyle:UITableViewStyleGrouped]) {
		_username = [username retain];
		self.title = @"Events";
	}
	return self;
}
- (void)viewDidLoad {
	UISearchBar *bar = [[UISearchBar alloc] initWithFrame:CGRectMake(0,0,self.view.bounds.size.width, 45)];
	bar.placeholder = @"Search Events";
	self.tableView.tableHeaderView = bar;
	[bar release];
}
- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	[_events release];
	_events = [[[LastFMService sharedInstance] eventsForUser:_username] retain];

	[self showNowPlayingButton:[(MobileLastFMApplicationDelegate *)[UIApplication sharedApplication].delegate isPlaying]];
	[self.tableView reloadData];
	[self.tableView setContentOffset:CGPointMake(0,self.tableView.tableHeaderView.frame.size.height)];
}
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 4;
}
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	if(section == 0 && [_events count]) {
		return @"Upcoming Events";
	} else {
		return nil;
	}
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	if(section == 0)
		return ([_events count] > 5)?5:[_events count];
	else
		return 1;
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	if([indexPath section] == 0)
		return 64;
	else
		return 46;
}
-(void)_rowSelected:(NSIndexPath *)newIndexPath {
	UINavigationController *controller = nil;
	NSArray *data = nil;
	
	switch([newIndexPath section]) {
		case 0:
		{
			EventDetailsViewController *details = [[EventDetailsViewController alloc] initWithEvent:[_events objectAtIndex:[newIndexPath row]]];
			[((MobileLastFMApplicationDelegate*)[UIApplication sharedApplication].delegate).rootViewController pushViewController:details animated:YES];
			[details release];
			break;
		}
		case 1:
			data = [[LastFMService sharedInstance] recommendedEventsForUser:_username];
			controller = [[EventListViewController alloc] initWithEvents:data];
			controller.title = @"Recommended Events";
			break;
		case 2:
			if (nil == _locationManager)
        _locationManager = [[CLLocationManager alloc] init];
			
			_locationManager.delegate = self;
			_locationManager.desiredAccuracy = kCLLocationAccuracyKilometer;
			
			// Set a movement threshold for new events
			_locationManager.distanceFilter = 500;
			
			[_locationManager startUpdatingLocation];
			return;
			break;
	}
	
	if(controller) {
		[((MobileLastFMApplicationDelegate *)[UIApplication sharedApplication].delegate).rootViewController pushViewController:controller animated:YES];
		[controller release];
	}
	[[self tableView] reloadData];
}
// Delegate method from the CLLocationManagerDelegate protocol.
- (void)locationManager:(CLLocationManager *)manager
    didUpdateToLocation:(CLLocation *)newLocation
					 fromLocation:(CLLocation *)oldLocation
{
	if(_locationManager != nil) {
			NSLog(@"latitude %+.6f, longitude %+.6f\n",
						newLocation.coordinate.latitude,
						newLocation.coordinate.longitude);
		[_locationManager stopUpdatingLocation];
		NSArray *data = [[LastFMService sharedInstance] eventsForLatitude:newLocation.coordinate.latitude longitude:newLocation.coordinate.longitude radius:50];
		UINavigationController *controller = [[EventListViewController alloc] initWithEvents:data];
		if(controller) {
			controller.title = @"Events Near Me";
			[((MobileLastFMApplicationDelegate *)[UIApplication sharedApplication].delegate).rootViewController pushViewController:controller animated:YES];
			[controller release];
		}
		//[_locationManager release];
		_locationManager = nil;
		[[self tableView] reloadData];
	}
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)newIndexPath {
	[[tableView cellForRowAtIndexPath: newIndexPath] showProgress:YES];
	[tableView deselectRowAtIndexPath:newIndexPath animated:YES];
	[self performSelector:@selector(_rowSelected:) withObject:newIndexPath afterDelay:0.5];
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"simplecell"];
	if (cell == nil) {
		cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"simplecell"] autorelease];
	}
	
	[cell showProgress: NO];
	
	switch([indexPath section]) {
		case 0:
		{
			MiniEventCell *eventCell = (MiniEventCell *)[tableView dequeueReusableCellWithIdentifier:@"minieventcell"];
			if (eventCell == nil) {
				eventCell = [[[MiniEventCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"minieventcell"] autorelease];
			}
			
			NSDictionary *event = [_events objectAtIndex:[indexPath row]];
			eventCell.title.text = [event objectForKey:@"headliner"];
			eventCell.location.text = [NSString stringWithFormat:@"%@\n%@, %@", [event objectForKey:@"venue"], [event objectForKey:@"city"], [event objectForKey:@"country"]];
			eventCell.location.lineBreakMode = UILineBreakModeWordWrap;
			eventCell.location.numberOfLines = 0;
			NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
			[formatter setLocale:[[[NSLocale alloc] initWithLocaleIdentifier:@"en_US"] autorelease]];
			[formatter setDateFormat:@"EEE, dd MMM yyyy HH:mm:ss"]; //"Fri, 21 Jan 2011 21:00:00"
			NSDate *date = [formatter dateFromString:[event objectForKey:@"startDate"]];
			[formatter setLocale:[NSLocale currentLocale]];
			
			[formatter setDateFormat:@"MMM"];
			eventCell.month.text = [formatter stringFromDate:date];
			
			[formatter setDateFormat:@"d"];
			eventCell.day.text = [formatter stringFromDate:date];
			
			[formatter release];
			eventCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

			[eventCell showProgress:NO];
			
			return eventCell;
		}
		case 1:
			cell.textLabel.text = @"Recommended by Last.fm";
			break;
		case 2:
			cell.textLabel.text = @"Events Near Me";
			break;
		case 3:
			cell.textLabel.text = @"My Friends Events";
			break;
	}
	[cell showProgress: NO];
	cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	return cell;
}
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
- (void)dealloc {
	[super dealloc];
	[_username release];
}
@end

@implementation EventListViewController

- (id)initWithEvents:(NSArray *)events {
	
	if (self = [super initWithStyle:UITableViewStyleGrouped]) {
		_events = [events retain];
	}
	return self;
}
- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	[self showNowPlayingButton:[(MobileLastFMApplicationDelegate *)[UIApplication sharedApplication].delegate isPlaying]];
	[self.tableView reloadData];
}
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return [_events count];
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return 64;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)newIndexPath {
	EventDetailsViewController *details = [[EventDetailsViewController alloc] initWithEvent:[_events objectAtIndex:[newIndexPath row]]];
	[((MobileLastFMApplicationDelegate*)[UIApplication sharedApplication].delegate).rootViewController pushViewController:details animated:YES];
	[details release];
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	MiniEventCell *eventCell = (MiniEventCell *)[tableView dequeueReusableCellWithIdentifier:@"minieventcell"];
	if (eventCell == nil) {
		eventCell = [[[MiniEventCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"minieventcell"] autorelease];
	}
	
	NSDictionary *event = [_events objectAtIndex:[indexPath row]];
	eventCell.title.text = [event objectForKey:@"headliner"];
	eventCell.location.text = [NSString stringWithFormat:@"%@\n%@, %@", [event objectForKey:@"venue"], [event objectForKey:@"city"], [event objectForKey:@"country"]];
	eventCell.location.lineBreakMode = UILineBreakModeWordWrap;
	eventCell.location.numberOfLines = 0;
	NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
	[formatter setLocale:[[[NSLocale alloc] initWithLocaleIdentifier:@"en_US"] autorelease]];
	[formatter setDateFormat:@"EEE, dd MMM yyyy HH:mm:ss"]; //"Fri, 21 Jan 2011 21:00:00"
	NSDate *date = [formatter dateFromString:[event objectForKey:@"startDate"]];
	[formatter setLocale:[NSLocale currentLocale]];
	
	[formatter setDateFormat:@"MMM"];
	eventCell.month.text = [formatter stringFromDate:date];
	
	[formatter setDateFormat:@"d"];
	eventCell.day.text = [formatter stringFromDate:date];
	
	[formatter release];
	eventCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	
	[eventCell showProgress:NO];
	
	return eventCell;
}
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
- (void)dealloc {
	[super dealloc];
	[_events release];
}
@end
