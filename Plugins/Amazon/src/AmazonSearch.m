//
//  AmazonSearch.m
//  MetaZ
//
//  Created by Brian Olsen on 20/11/09.
//  Copyright 2009 Maven-Group. All rights reserved.
//

#import "AmazonSearch.h"
#import "Access.h"
#import "AmazonRequest.h"
#import <GTMStackTrace.h>

@implementation AmazonSearch

+ (Class)restWrapper
{
    return [AmazonRequest class];
}

+ (id)searchWithProvider:(id)provider delegate:(id<MZSearchProviderDelegate>)delegate url:(NSURL *)url parameters:(NSDictionary *)params
{
    return [[[self alloc] initWithProvider:provider delegate:delegate url:url parameters:params] autorelease];
}

- (id)initWithProvider:(id)theProvider delegate:(id<MZSearchProviderDelegate>)theDelegate url:(NSURL *)url parameters:(NSDictionary *)params;
{
    self = [super initWithProvider:theProvider delegate:theDelegate url:url usingVerb:@"GET" parameters:params];
    if(self)
    {
        NSArray* tags = [NSArray arrayWithObjects:
            MZTitleTagIdent, 
            MZDirectorTagIdent, MZProducerTagIdent,
            MZScreenwriterTagIdent, MZActorsTagIdent,
            MZShortDescriptionTagIdent,
            MZASINTagIdent,
            
            MZLongDescriptionTagIdent,
            MZAdvisoryTagIdent, MZCopyrightTagIdent,
            MZCommentTagIdent, MZArtistTagIdent,
            MZTVShowTagIdent, MZTVSeasonTagIdent,
            MZTVEpisodeTagIdent, MZTVNetworkTagIdent,
            MZSortTitleTagIdent, MZSortAlbumArtistTagIdent,
            MZSortAlbumTagIdent, MZSortTVShowTagIdent,
            MZGenreTagIdent,
            nil];
        NSArray* keys = [NSArray arrayWithObjects:
            @"ItemAttributes/Title",
            @"ItemAttributes/Director", @"ItemAttributes/Creator[@Role='Producer']",
            @"ItemAttributes/Creator[@Role='Writer']", @"ItemAttributes/Actor",
            @"ItemAttributes/Feature",
            @"ASIN",
            
            @"movieTags/info/longDescription",
            @"movieTags/info/advisory", @"movieTags/info/copyright",
            @"movieTags/info/comments", @"movieTags/info/artist/artistName",
            @"movieTags/television/showName", @"movieTags/television/season",
            @"movieTags/television/episode", @"movieTags/television/network",
            @"movieTags/sorting/name", @"movieTags/sorting/albumArtist",
            @"movieTags/sorting/album", @"movieTags/sorting/show",
            @"movieTags/info/genre", 
            nil];
        mapping = [[NSDictionary alloc] initWithObjects:tags forKeys:keys];

        int ratings[] = { 
            MZNoRating, MZ_PG13_Rating,
            MZ_NC17_Rating, MZ_G_Rating,
            MZ_R_Rating, MZ_PG_Rating,
            -1
        };
        NSArray* ratingNames = [[NSArray alloc] initWithObjects:
            @"NR (Not Rated)", @"PG-13 (Parental Guidance Suggested)",
            @"X (Mature Audiences Only)", @"G (General Audience)",
            @"R (Restricted)", @"PG (Parental Guidance Suggested)",
            nil];
        int ratingsCount;
        for(ratingsCount=0; ratingsCount<[ratingNames count]+5 && ratings[ratingsCount] > -1;ratingsCount++);
        NSLog(@"Ratings %d %d", [ratingNames count], ratingsCount);
        NSAssert([ratingNames count] == ratingsCount, @"Bad number of ratings");
        NSMutableDictionary* map = [NSMutableDictionary dictionaryWithCapacity:ratingsCount];
        for(int i=0; i<ratingsCount; i++)
        {
            NSNumber* value = [NSNumber numberWithInt:ratings[i]];
            [map setObject:value forKey:[ratingNames objectAtIndex:i]];
        }
        ratingsMap = [[NSDictionary alloc] initWithDictionary:map];
        /*
            //US
            MZ_G_Rating, MZ_PG_Rating, MZ_PG13_Rating, MZ_R_Rating, MZ_NC17_Rating, MZ_Unrated_Rating,
            //US-TV
            MZ_TVY7_Rating, MZ_TVY_Rating, MZ_TVG_Rating, MZ_TVPG_Rating, MZ_TV14_Rating, MZ_TVMA_Rating,
            // UK
            MZ_U_Rating, MZ_Uc_Rating, MZ_PG_UK_Rating, MZ_12_UK_Rating, MZ_12A_Rating, MZ_15_UK_Rating, MZ_18_UK_Rating, MZ_E_UK_Rating, MZ_Unrated_UK_Rating,
            // DE
            MZ_FSK0_Rating, MZ_FSK6_Rating, MZ_FSK12_Rating, MZ_FSK16_Rating, MZ_FSK18_Rating,
            // IE
            MZ_G_IE_Rating, MZ_PG_IE_Rating, MZ_12_IE_Rating, MZ_15_IE_Rating, MZ_16_Rating, MZ_18_IE_Rating, MZ_Unrated_IE_Rating,
            // IE-TV
            MZ_GA_Rating, MZ_Ch_Rating, MZ_YA_Rating, MZ_PS_Rating, MZ_MA_IETV_Rating, MZ_Unrated_IETV_Rating,
            // CA
            MZ_G_CA_Rating, MZ_PG_CA_Rating, MZ_14_Rating, MZ_18_CA_Rating, MZ_R_CA_Rating, MZ_E_CA_Rating, MZ_Unrated_CA_Rating,
            // CA-TV
            MZ_C_CATV_Rating, MZ_C8_Rating, MZ_G_CATV_Rating, MZ_PG_CATV_Rating, MZ_14Plus_Rating, MZ_18Plus_Rating, MZ_Unrated_CATV_Rating,
            // AU
            MZ_E_AU_Rating, MZ_G_AU_Rating, MZ_PG_AU_Rating, MZ_M_AU_Rating, MZ_MA15Plus_AU_Rating, MZ_R18Plus_Rating, MZ_Unrated_AU_Rating,
            // AU-TV
            MZ_P_Rating, MZ_C_AUTV_Rating, MZ_G_AUTV_Rating, MZ_PG_AUTV_Rating, MZ_M_AUTV_Rating, MZ_MA15Plus_AUTV_Rating, MZ_AV15Plus_Rating, MZ_Unrated_AUTV_Rating,    
            // NZ
            MZ_E_NZ_Rating, MZ_G_NZ_Rating, MZ_PG_NZ_Rating, MZ_M_NZ_Rating, MZ_R13_Rating, MZ_R15_Rating, MZ_R16_Rating, MZ_R18_Rating, MZ_R_NZ_Rating, MZ_Unrated_NZ_Rating,
            // NZ-TV
            MZ_G_NZTV_Rating, MZ_PGR_Rating, MZ_AO_Rating, MZ_Unrated_NZTV_Rating,
        };
        */
        
        AmazonRequest* req = (AmazonRequest*)wrapper;
        [req setAccessKeyId:AMAZON_ACCESS_ID];
        [req setSecretAccessKey:AMAZON_ACCESS_KEY];
    }
    return self;
}

- (void)dealloc
{
    [mapping release];
    [ratingsMap release];
    [super dealloc];
}

#pragma mark - MZRESTWrapperDelegate

- (void)wrapper:(MZRESTWrapper *)theWrapper didRetrieveData:(NSData *)data
{
    //MZLoggerDebug(@"Got amazon response:\n%@", [theWrapper responseAsText]);
    NSXMLDocument* doc = [theWrapper responseAsXml];

    NSString* errorMessage = [doc stringForXPath:@"/ItemSearchResponse/Items/Request/Errors/Error/Code" error:NULL];
    if(![errorMessage isEqual:@""])
        MZLoggerError(@"Amazon error: %@", errorMessage);
        
    //NSString* totalResults = [doc stringForXPath:@"/ItemSearchResponse/Items/TotalResults" error:NULL];
    //NSString* totalPages = [doc stringForXPath:@"/ItemSearchResponse/Items/TotalPages" error:NULL];

    NSArray* items = [doc nodesForXPath:@"/ItemSearchResponse/Items/Item" error:NULL];
    NSMutableArray* results = [NSMutableArray array];
    MZLoggerDebug(@"Got Amazon results %d", [items count]);
    for(NSXMLElement* item in items)
    {
        NSMutableDictionary* dict = [NSMutableDictionary dictionary];
        for(NSString* xpath in [mapping allKeys])
        {
            NSString* tagId = [mapping objectForKey:xpath];
            MZTag* tag = [MZTag tagForIdentifier:tagId];
            NSString* value = [item stringForXPath:xpath error:NULL];
            if([value length] > 0)
            {
                id obj = [tag objectFromString:value];
                if(obj)
                    [dict setObject:obj forKey:tagId];
            }
        }

        NSArray* reviews = [item nodesForXPath:@"EditorialReviews/EditorialReview/Content" error:NULL];
        if([reviews count] > 0)
        {
            NSString* review = [[reviews objectAtIndex:0] stringValue];
            [dict setObject:review forKey:MZLongDescriptionTagIdent];
        }

        MZTag* ratingTag = [MZTag tagForIdentifier:MZRatingTagIdent];
        NSString* rating = [item stringForXPath:@"ItemAttributes/AudienceRating" error:NULL];
        NSNumber* ratingNr = [ratingsMap objectForKey:rating];
        if(!ratingNr)
            ratingNr = [ratingTag objectFromString:rating];
        if([ratingNr intValue] != MZNoRating)
            [dict setObject:ratingNr forKey:MZRatingTagIdent];
        /*
        NSInteger ratingNr = [ratingNames indexOfObject:rating];
        if(ratingNr != NSNotFound)
        {
            [dict setObject:[NSNumber numberWithInt:ratingNr] forKey:MZRatingTagIdent];
        }
        */


        NSString* coverArtLarge = [item stringForXPath:@"LargeImage/URL" error:NULL];
        if([coverArtLarge length] > 0)
        {
            /*
            MZLoggerDebug(@"ASIN %@", asin);
            MZLoggerDebug(@"Image large url: %@", coverArtLarge);
            */
            NSURL* url = [NSURL URLWithString:coverArtLarge];
            MZRemoteData* data = [MZRemoteData dataWithURL:url];
            [dict setObject:data forKey:MZPictureTagIdent];
            [data loadData];
        }

        MZSearchResult* result = [MZSearchResult resultWithOwner:provider dictionary:dict];
        [results addObject:result];
    }

    MZLoggerDebug(@"Parsed Amazon results %d", [results count]);
    [delegate searchProvider:provider result:results];
    
    // TODO Make more requests for other pages
    [super wrapper:theWrapper didRetrieveData:data];
}

- (void)addObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath options:(NSKeyValueObservingOptions)options context:(void *)context
{
    [super addObserver:observer forKeyPath:keyPath options:options context:context];
}

- (void)removeObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath
{
    [super removeObserver:observer forKeyPath:keyPath];
}

@end
