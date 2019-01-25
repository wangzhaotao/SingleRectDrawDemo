//
//  TJRectModel.m
//  OpenCVFaceDetectDemo
//
//  Created by WZT on 2018/11/14.
//  Copyright © 2018年 WZT. All rights reserved.
//



/*
 * 1.顶点排序为：顺序--影响翻转、反转
 *   A--E--B
 *   |     |
 *   |     |
 *   H     F
 *   |     |
 *   |     |
 *   D--G--C
 *
 * 2.四边形判断：
 *   (1)内角和=360度，是四边形；否则对顶点数组全排列，挨个尝试(交叉时，总有一个可以；内四边形时，均不可以)
 *   (2)>或者<360，由于向量夹角范围为0~180, 所以这个没法判断；
 *   (3)通过判断B、C是否在对角线AC同一侧，来判断是否为内四边形；
 *
 * 3.通过全排列的顶点数组，由于顺序问题可能导致反转、翻转问题出现；
 首先求得最上面的两点；最下面的两点；
 然后分别根据x轴坐标，确定出ABCD点；
 */

#import "TJRectModel.h"

static CGFloat const kRectLineWidth = 1;
static CGFloat const kRectArcWidth = 6;
static CGFloat const kRectPointMinDistance = 30;

//angleA+angleB+angleC+angleD=360:四边形-0; >360:内四边形-1; <360:有交叉-2;
typedef NS_ENUM(NSInteger, QuadrilateralType) {
    QuadrilateralType_IsQuadrilateral,     //四边形
    QuadrilateralType_InsideQuadrilateral, //内四边形
    QuadrilateralType_NotQuadrilateral,    //有交叉，不是四边形
};

@interface TJRectModel ()
{
    NSMutableArray *_pointsArray;
}
@property (nonatomic, assign) NSInteger currentMovingPointIndex;
//顶点坐标ABCD
@property (nonatomic, readwrite) NSMutableArray *cornerPoints;

@end

@implementation TJRectModel




#pragma mark set/get
-(NSMutableArray*)pointsArray {
    if (!_pointsArray) {
        _pointsArray = [NSMutableArray array];
    }
    return _pointsArray;
}
-(void)setPointsArray:(NSMutableArray *)pointsArray {
    _pointsArray = [NSMutableArray arrayWithArray:pointsArray];
    
    //调整ABCD点的顺序
    //重新确定四个边角点顺序
    if (_pointsArray.count>=4) {
        NSMutableArray *temp = [[_pointsArray subarrayWithRange:NSMakeRange(0, 4)] mutableCopy];
        [self justfyFourCornerPointsAndToDoSomething:temp];
    }
}
//顶点坐标ABCD
-(NSMutableArray*)cornerPoints {
    NSArray *temp = [_pointsArray subarrayWithRange:NSMakeRange(0, 4)];
    NSLog(@"排序前顶点坐标:%@", temp);
    NSArray *sortedYArr = [self resetOrderOfCornerPointsByABCD:temp];
    NSLog(@"排序后顶点坐标:%@", sortedYArr);
    
    _cornerPoints = [NSMutableArray arrayWithArray:sortedYArr];
    return _cornerPoints;
}
//将数组按照y轴坐标升序排列
-(NSArray*)resetOrderOfCornerPointsByABCD:(NSArray*)points{
    
    NSArray *sortedArray = nil;
    
    //最上方的两个点
    sortedArray = [points sortedArrayUsingComparator:^NSComparisonResult(NSArray *obj1, NSArray *obj2) {
        return [obj1[1] compare:obj2[1]]; //升序
    }];
    //A、B
    NSArray *pointA = sortedArray[0];
    NSArray *pointB = sortedArray[1];
    if ([pointA[0] floatValue]>[pointB[0]floatValue]) {
        NSArray *temp = pointA;
        pointA = pointB;
        pointB = temp;
    }
    //C、D
    NSArray *pointC = sortedArray[2];
    NSArray *pointD = sortedArray[3];
    if ([pointC[0] floatValue]<[pointD[0] floatValue]) {
        NSArray *temp = pointC;
        pointC = pointD;
        pointD = temp;
    }
    return @[pointA, pointB, pointC, pointD];
}


#pragma mark public methods
-(void)redraw {
    
    //画出四个交点 及 连线
    /* 上下文 */
    CGContextRef context = UIGraphicsGetCurrentContext();
    if (self.isInQuadrilateral){
        CGContextSetRGBFillColor(context, 100/255.0, 100/255.0, 100/255.0, 1);
        CGContextSetRGBStrokeColor(context, 100/255.0, 100/255.0, 100/255.0, 1);
    }else{
        CGContextSetRGBFillColor(context, 255/255.0, 106/255.0, 0/255.0, 1);
        CGContextSetRGBStrokeColor(context, 255/255.0, 106/255.0, 0/255.0, 1);
    }
    
    /* 边框圆 A B C D E F G H
     A--E--B
     |     |
     H     F
     |     |
     D--G--C
     */
    /* 边框圆 A B C D E F G H 8个点 */
    for (NSArray *pArr in _pointsArray) {
        [self drawACircleWithPoint:pArr withContextRef:context];
    }
    
    /* 画边框连线 */
    CGContextSetLineWidth(context, 4);
    CGPoint points[5];
    points[0] = [self getCGPointWithNumbersArray:_pointsArray[0]]; //A
    points[1] = [self getCGPointWithNumbersArray:_pointsArray[1]]; //B
    points[2] = [self getCGPointWithNumbersArray:_pointsArray[2]]; //C
    points[3] = [self getCGPointWithNumbersArray:_pointsArray[3]]; //D
    points[4] = [self getCGPointWithNumbersArray:_pointsArray[0]]; //A
    CGContextAddLines(context, points, 5);
    CGContextDrawPath(context, kCGPathStroke);
}
//NSArray <-->CGPoint 转换
-(CGPoint)getCGPointWithNumbersArray:(NSArray*)numberArr
{
    CGFloat x = [numberArr[0] floatValue];
    CGFloat y = [numberArr[1] floatValue];
    CGPoint t = CGPointMake(x,y);
    t = [self setMaxMinValuePoint:t];
    return t;
}
-(NSArray*)getNumbersArrayWithCGPoint:(CGPoint)point
{
    point = [self setMaxMinValuePoint:point];
    return @[[NSNumber numberWithFloat:point.x], [NSNumber numberWithFloat:point.y]];
}
//检测触摸点是否在交点范围内
-(NSInteger)searchPointContainedTouch:(CGPoint)touch
{
    //求出里触摸点最近的点
    NSInteger touchIndex= [self eachPointsAndGetMinDistanceIndexWith:touch];
    if (touchIndex!=-1) {
        NSArray *p = [_pointsArray objectAtIndex:touchIndex];
        //判断最近点是否在触摸范围内
        if ([self isTouchContainedPoint:p withTouch:touch]) {
            return touchIndex;
        }
    }
    
    return -1;
}
-(BOOL)isTouchRectWithPoint:(CGPoint)point {
    
    NSInteger touchPointIndex = [self searchPointContainedTouch:point];
    if (touchPointIndex!=-1) {
        return YES;
    }
    
    return NO;
}
-(NSInteger)searchLineCenterContainedTouchPoint:(CGPoint)point {
    
    /* 边框圆 A B C D E F G H
     A--E--B
     |     |
     H     F
     |     |
     D--G--C
     */
    //A
    NSArray *tempA = _pointsArray[0];
    //B
    NSArray *tempB = _pointsArray[1];
    //C
    NSArray *tempC = _pointsArray[2];
    //D
    NSArray *tempD = _pointsArray[3];
    //直线AB AD BD DA
    TJLineModel *lineAB = [TJLineModel newLineModelWithPoint1:CGPointMake([tempA[0] floatValue], [tempA[1] floatValue]) point2:CGPointMake([tempB[0] floatValue], [tempB[1] floatValue])];
    TJLineModel *lineBC = [TJLineModel newLineModelWithPoint1:CGPointMake([tempB[0] floatValue], [tempB[1] floatValue]) point2:CGPointMake([tempC[0] floatValue], [tempC[1] floatValue])];
    TJLineModel *lineCD = [TJLineModel newLineModelWithPoint1:CGPointMake([tempC[0] floatValue], [tempC[1] floatValue]) point2:CGPointMake([tempD[0] floatValue], [tempD[1] floatValue])];
    TJLineModel *lineDA = [TJLineModel newLineModelWithPoint1:CGPointMake([tempD[0] floatValue], [tempD[1] floatValue]) point2:CGPointMake([tempA[0] floatValue], [tempA[1] floatValue])];
    
    if ([lineAB isTouchLineWithPoint:point]) {
        return 4;
    }
    if ([lineBC isTouchLineWithPoint:point]) {
        return 5;
    }
    if ([lineCD isTouchLineWithPoint:point]) {
        return 6;
    }
    if ([lineDA isTouchLineWithPoint:point]) {
        return 7;
    }
    
    return -1;
}

#pragma mark 手势触摸事件
-(void)touchBeginWithPoint:(CGPoint)point {
    
    _currentMovingPointIndex = [self searchPointContainedTouch:point];
    if (_currentMovingPointIndex == -1) {
        [self touchCancelWithPoint:point];
    }
}
-(void)touchMovingWithPoint:(CGPoint)point {
    
    CGPoint p = [self setMaxMinValuePoint:point];
    NSArray *newTouch = @[[NSNumber numberWithFloat:p.x],[NSNumber numberWithFloat:p.y]];
    
    //
    if (_currentMovingPointIndex!=-1 && _currentMovingPointIndex<_pointsArray.count) {
        
        //重绘
        if (_currentMovingPointIndex<4) {
            if (!_isOnlyRectMoving) {
                [_pointsArray replaceObjectAtIndex:_currentMovingPointIndex withObject:newTouch];
            }else{
                [self onlyRectMovingPoint:newTouch currentIndex:_currentMovingPointIndex];
                [_pointsArray replaceObjectAtIndex:_currentMovingPointIndex withObject:newTouch];
                
                //判断对角顶点，最小间距
//                if (![self drawableJudgeRectTwoPointInMinDistance]) {
//                    [self touchCancelWithPoint:point];
//                }
            }
        }else{
            //根据中间点的位移，确定两端点的位移
            [self resetTwoPointsByCenterPointWithTouch:p];
        }
        //四个边角点 A B C D，重新初始化中点
        [self initCenterPointBetweenTwo];
        
        //[self redraw];
        if (self.delegate && [self.delegate respondsToSelector:@selector(redrawRect)]) {
            [self.delegate redrawRect];
        }
    }
}
-(void)touchEndWithPoint:(CGPoint)point {
    
    //重新确定四个边角点顺序
    NSMutableArray *temp = [[_pointsArray subarrayWithRange:NSMakeRange(0, 4)] mutableCopy];
    [self justfyFourCornerPointsAndToDoSomething:temp];
}
-(void)touchCancelWithPoint:(CGPoint)point {
    
    //检测是否为内四边形
    _isInQuadrilateral = [self justifyIsInQuadrilateralWithIndex:_currentMovingPointIndex];
}





#pragma mark private methods
//判断对角顶点，最小间距
-(BOOL)drawableJudgeRectTwoPointInMinDistance {
    
    NSArray *pointA = [_pointsArray objectAtIndex:0];
    NSArray *pointB = [_pointsArray objectAtIndex:1];
    NSArray *pointC = [_pointsArray objectAtIndex:2];
    NSArray *pointD = [_pointsArray objectAtIndex:3];
    
    CGFloat acX2 = pow([pointA[0] floatValue]-[pointC[0] floatValue], 2);
    CGFloat acY2 = pow([pointA[1] floatValue]-[pointC[1] floatValue], 2);
    CGFloat acDistance = sqrtf(acX2+acY2);
    
    CGFloat bdX2 = pow([pointB[0] floatValue]-[pointD[0] floatValue], 2);
    CGFloat bdY2 = pow([pointB[1] floatValue]-[pointD[1] floatValue], 2);
    CGFloat bdDistance = sqrtf(bdX2+bdY2);
    if (acDistance>kRectPointMinDistance && bdDistance>kRectPointMinDistance) {
        return YES;
    }
    return NO;
}
//限制只进行矩形位移
-(void)onlyRectMovingPoint:(NSArray*)movingP currentIndex:(NSInteger)index {
    if (movingP.count<2) {
        return;
    }
    /* 边框圆 A B C D E F G H
     A--E--B
     |     |
     H     F
     |     |
     D--G--C
     */
    if (index<_pointsArray.count) {
        NSArray *oldPointArr = [_pointsArray objectAtIndex:index];
        NSInteger dx = [movingP[0] integerValue]-[oldPointArr[0] integerValue];
        NSInteger dy = [movingP[1] integerValue]-[oldPointArr[1] integerValue];
        
        switch (index) {
            case 0:
            {
                //A
                NSArray *pointB = [_pointsArray objectAtIndex:1];
                NSArray *pointD = [_pointsArray objectAtIndex:3];
                
                pointB = @[pointB[0], [NSNumber numberWithFloat:([pointB[1]integerValue]+dy)]];
                pointD = @[[NSNumber numberWithFloat:([pointD[0]integerValue]+dx)], pointD[1]];
                [_pointsArray replaceObjectAtIndex:1 withObject:pointB];
                [_pointsArray replaceObjectAtIndex:3 withObject:pointD];
                break;
            }
            case 1:
            {
                //B
                NSArray *pointA = [_pointsArray objectAtIndex:0];
                NSArray *pointC = [_pointsArray objectAtIndex:2];
                
                pointA = @[pointA[0], [NSNumber numberWithFloat:([pointA[1]integerValue]+dy)]];
                pointC = @[[NSNumber numberWithFloat:([pointC[0]integerValue]+dx)], pointC[1]];
                [_pointsArray replaceObjectAtIndex:0 withObject:pointA];
                [_pointsArray replaceObjectAtIndex:2 withObject:pointC];
                break;
            }
            case 2:
            {
                //C
                NSArray *pointB = [_pointsArray objectAtIndex:1];
                NSArray *pointD = [_pointsArray objectAtIndex:3];
                
                pointD = @[pointD[0], [NSNumber numberWithFloat:([pointD[1]integerValue]+dy)]];
                pointB = @[[NSNumber numberWithFloat:([pointB[0]integerValue]+dx)], pointB[1]];
                [_pointsArray replaceObjectAtIndex:1 withObject:pointB];
                [_pointsArray replaceObjectAtIndex:3 withObject:pointD];
                break;
            }
            case 3:
            {
                //D
                NSArray *pointA = [_pointsArray objectAtIndex:0];
                NSArray *pointC = [_pointsArray objectAtIndex:2];
                
                pointC = @[pointC[0], [NSNumber numberWithFloat:([pointC[1]integerValue]+dy)]];
                pointA = @[[NSNumber numberWithFloat:([pointA[0]integerValue]+dx)], pointA[1]];
                [_pointsArray replaceObjectAtIndex:0 withObject:pointA];
                [_pointsArray replaceObjectAtIndex:2 withObject:pointC];
                break;
            }
                
            default:
                break;
        }
    }
    
    //矩形纠正
    {
        NSArray *pointA = [_pointsArray objectAtIndex:0];
        NSArray *pointB = [_pointsArray objectAtIndex:1];
        NSArray *pointC = [_pointsArray objectAtIndex:2];
        NSArray *pointD = [_pointsArray objectAtIndex:3];
        //AB
        if ([pointA[1]integerValue]!=[pointB[1]integerValue]) {
            NSInteger abY = ([pointA[1]integerValue]+[pointB[1]integerValue])/2;
            pointA = @[pointA[0], [NSNumber numberWithInteger:abY]];
            pointB = @[pointB[0], [NSNumber numberWithInteger:abY]];
        }
        //BC
        if ([pointB[0]integerValue]!=[pointC[0]integerValue]) {
            NSInteger bcX = ([pointB[0]integerValue]+[pointC[0]integerValue])/2;
            pointB = @[[NSNumber numberWithInteger:bcX], pointB[1]];
            pointC = @[[NSNumber numberWithInteger:bcX], pointC[1]];
        }
        //CD
        if ([pointC[1]integerValue]!=[pointD[1]integerValue]) {
            NSInteger cdY = ([pointC[1]integerValue]+[pointD[1]integerValue])/2;
            pointC = @[pointC[0], [NSNumber numberWithInteger:cdY]];
            pointD = @[pointD[0], [NSNumber numberWithInteger:cdY]];
        }
        //DA
        if ([pointA[0]integerValue]!=[pointD[0]integerValue]) {
            NSInteger adX = ([pointA[0]integerValue]+[pointD[0]integerValue])/2;
            pointA = @[[NSNumber numberWithInteger:adX], pointA[1]];
            pointD = @[[NSNumber numberWithInteger:adX], pointD[1]];
        }
    }
}

//画边框圆-交点
-(void)drawACircleWithPoint:(NSArray*)point withContextRef:(CGContextRef)context
{
    if (point.count==2) {
        
        CGFloat x = [point[0] floatValue];
        CGFloat y = [point[1] floatValue];
        /* 边框圆 */
        CGFloat lineWidth = kRectLineWidth, arcWidth = kRectArcWidth;
        CGContextSetLineWidth(context, lineWidth);
        CGContextAddArc(context, x, y, arcWidth, 0, 2*M_PI, 0);
        CGContextDrawPath(context, kCGPathFillStroke);
    }
}
//设置最大最小范围
-(CGPoint)setMaxMinValuePoint:(CGPoint)point
{
    CGFloat maxW = _max_width;
    CGFloat maxH = _max_height;
    if (maxW==0) {
        maxW = [[UIScreen mainScreen]bounds].size.width;
    }
    if (maxH==0) {
        maxH = [[UIScreen mainScreen]bounds].size.height;
    }
    
    CGFloat x = point.x>maxW?maxW:point.x;
    x = x<0?0:x;
    CGFloat y = point.y>maxH?maxH:point.y;
    y = y<0?0:y;
    
    return CGPointMake(x, y);
}
//判断是否在点的触摸范围内
-(BOOL)isTouchContainedPoint:(NSArray*)point withTouch:(CGPoint)touch
{
    BOOL isContained = NO;
    CGFloat dX2 = pow(touch.x-[point[0] floatValue], 2);
    CGFloat dY2 = pow(touch.y-[point[1] floatValue], 2);
    CGFloat distance = sqrtf(dX2+dY2);
    
    if (distance<kRectPointMinDistance) {
        isContained = YES;
    }
    return isContained;
}
//遍历点 判断离触摸点最近的点
-(NSInteger)eachPointsAndGetMinDistanceIndexWith:(CGPoint)touch
{
    NSMutableArray *temp = [NSMutableArray array];
    
    for (int i=0;i<_pointsArray.count;i++) {
        NSArray *p = [_pointsArray objectAtIndex:i];
        
        CGFloat dX2 = pow(touch.x-[p[0] floatValue], 2);
        CGFloat dY2 = pow(touch.y-[p[1] floatValue], 2);
        CGFloat distance = sqrtf(dX2+dY2);
        
        [temp addObject:[NSNumber numberWithFloat:distance]];
    }
    
    CGFloat minV = 10000;
    NSInteger index = -1;
    for (int i=0; i<temp.count; i++) {
        NSNumber *temp_Num = temp[i];
        
        if (minV>[temp_Num floatValue]) {
            minV = [temp_Num floatValue];
            index = i;
        }
    }
    return index;
}

#pragma mark 四边形判断准则2 - 根据四边形内角和=360; >360:内四边形; <360:重排列;
//根据四个顶点坐标，初始化四边形四条边的中间点
-(void)initCenterPointBetweenTwo
{
    /* 边框圆 A B C D E F G H
     A--E--B
     |     |
     H     F
     |     |
     D--G--C
     */
    //A
    NSArray *tempA = _pointsArray[0];
    //B
    NSArray *tempB = _pointsArray[1];
    //C
    NSArray *tempC = _pointsArray[2];
    //D
    NSArray *tempD = _pointsArray[3];
    if (_pointsArray.count>4) {
        [_pointsArray removeObjectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(4, 4)]];
    }
    
    /* E F G H*/
    //E
    [_pointsArray addObject:[self getCenterNumberArrayWithNumberArray1:tempA point2:tempB]];
    //F
    [_pointsArray addObject:[self getCenterNumberArrayWithNumberArray1:tempB point2:tempC]];
    //G
    [_pointsArray addObject:[self getCenterNumberArrayWithNumberArray1:tempC point2:tempD]];
    //H
    [_pointsArray addObject:[self getCenterNumberArrayWithNumberArray1:tempA point2:tempD]];
}
//求两点之间的中点坐标
-(NSArray*)getCenterNumberArrayWithNumberArray1:(NSArray*)numArr1 point2:(NSArray*)numArr2
{
    CGFloat x = ([numArr1[0] floatValue]+[numArr2[0] floatValue])/2;
    CGFloat y = ([numArr1[1] floatValue]+[numArr2[1] floatValue])/2;
    return @[[NSNumber numberWithFloat:x], [NSNumber numberWithFloat:y]];
}
//手势拖动边的中点时，根据中间点的位移，确定两端点的位移
-(void)resetTwoPointsByCenterPointWithTouch:(CGPoint)touchPoint
{
    //四个中点   E F G H，中心初始化边角点
    NSArray *currentP = [_pointsArray objectAtIndex:_currentMovingPointIndex];
    CGFloat currentP_X = [[currentP objectAtIndex:0] floatValue];
    CGFloat currentP_Y = [[currentP objectAtIndex:1] floatValue];
    //位移
    CGFloat dY = touchPoint.y-currentP_Y;
    CGFloat dX = touchPoint.x-currentP_X;
    //当前触摸点更新
    CGPoint tp = [self setMaxMinValuePoint:CGPointMake(currentP_X+dX, currentP_Y+dY)];
    currentP = @[[NSNumber numberWithFloat:tp.x], [NSNumber numberWithFloat:tp.y]];
    [_pointsArray replaceObjectAtIndex:_currentMovingPointIndex withObject:currentP];
    
    /* 边框圆 A B C D E F G H
     A--E--B
     |     |
     H     F
     |     |
     D--G--C
     */
    //A
    NSArray *tempA = _pointsArray[0];
    //B
    NSArray *tempB = _pointsArray[1];
    //C
    NSArray *tempC = _pointsArray[2];
    //D
    NSArray *tempD = _pointsArray[3];
    //直线AB AD BD DA
    TJLineModel *lineAB = [TJLineModel newLineModelWithPoint1:CGPointMake([tempA[0] floatValue], [tempA[1] floatValue]) point2:CGPointMake([tempB[0] floatValue], [tempB[1] floatValue])];
    TJLineModel *lineBC = [TJLineModel newLineModelWithPoint1:CGPointMake([tempB[0] floatValue], [tempB[1] floatValue]) point2:CGPointMake([tempC[0] floatValue], [tempC[1] floatValue])];
    TJLineModel *lineCD = [TJLineModel newLineModelWithPoint1:CGPointMake([tempC[0] floatValue], [tempC[1] floatValue]) point2:CGPointMake([tempD[0] floatValue], [tempD[1] floatValue])];
    TJLineModel *lineDA = [TJLineModel newLineModelWithPoint1:CGPointMake([tempD[0] floatValue], [tempD[1] floatValue]) point2:CGPointMake([tempA[0] floatValue], [tempA[1] floatValue])];
    
    switch (_currentMovingPointIndex) {
        case 4: //A E B
        {
            //A
            //更新AB直线
            lineAB.centerPoint = CGPointMake(currentP_X+dX, currentP_Y+dY);
            //更新点A B
            CGPoint newPoint = [lineAB computeIntersectLine1:lineAB line2:lineDA];
            tempA = [self getNumbersArrayWithCGPoint:newPoint];
            [_pointsArray replaceObjectAtIndex:0 withObject:tempA];
            
            newPoint = [lineAB computeIntersectLine1:lineAB line2:lineBC];
            tempB = [self getNumbersArrayWithCGPoint:newPoint];
            [_pointsArray replaceObjectAtIndex:1 withObject:tempB];
        }
            break;
        case 5: //B F C
        {
            //F
            //更新BC直线
            lineBC.centerPoint = CGPointMake(currentP_X+dX, currentP_Y+dY);
            //更新点B C
            CGPoint newPoint = [lineAB computeIntersectLine1:lineAB line2:lineBC];
            tempB = [self getNumbersArrayWithCGPoint:newPoint];
            [_pointsArray replaceObjectAtIndex:1 withObject:tempB];
            
            newPoint = [lineAB computeIntersectLine1:lineBC line2:lineCD];
            tempC = [self getNumbersArrayWithCGPoint:newPoint];
            [_pointsArray replaceObjectAtIndex:2 withObject:tempC];
        }
            break;
        case 6: //C G D
        {
            //G
            //更新CD直线
            lineCD.centerPoint = CGPointMake(currentP_X+dX, currentP_Y+dY);
            //更新点C D
            CGPoint newPoint = [lineAB computeIntersectLine1:lineBC line2:lineCD];
            tempC = [self getNumbersArrayWithCGPoint:newPoint];
            [_pointsArray replaceObjectAtIndex:2 withObject:tempC];
            
            newPoint = [lineCD computeIntersectLine1:lineCD line2:lineDA];
            tempD = [self getNumbersArrayWithCGPoint:newPoint];
            [_pointsArray replaceObjectAtIndex:3 withObject:tempD];
        }
            break;
        case 7: //A H D
        {
            //H
            //更新AD直线
            lineDA.centerPoint = CGPointMake(currentP_X+dX, currentP_Y+dY);
            //更新点A D
            CGPoint newPoint = [lineAB computeIntersectLine1:lineAB line2:lineDA];
            tempA = [self getNumbersArrayWithCGPoint:newPoint];
            [_pointsArray replaceObjectAtIndex:0 withObject:tempA];
            
            newPoint = [lineAB computeIntersectLine1:lineDA line2:lineCD];
            tempD = [self getNumbersArrayWithCGPoint:newPoint];
            [_pointsArray replaceObjectAtIndex:3 withObject:tempD];
        }
            break;
            
        default:
            break;
    }
}
-(void)justfyFourCornerPointsAndToDoSomething:(NSMutableArray*)cornerPoints{
    
    QuadrilateralType type = [self countInsideAngleSummerWithCornerPoints:cornerPoints];
    switch (type) {
        case QuadrilateralType_IsQuadrilateral:
        {
            //四边形
            //_isInQuadrilateral = NO;
        }
            break;
        case QuadrilateralType_InsideQuadrilateral:
        {
            //内四边形
            //_isInQuadrilateral = YES;
        }
            break;
        case QuadrilateralType_NotQuadrilateral:
        {
            //不是四边形，边有交叉
            NSMutableArray *allRanges = [self allRangeOfFourCornerPoints:cornerPoints];
            
            //遍历全排列 并计算每个排列的四边形-内角和
            BOOL isResetCornerPoints = NO;
            for (NSArray *tempPoints in allRanges) {
                QuadrilateralType type = [self countInsideAngleSummerWithCornerPoints:tempPoints];
                if (type == QuadrilateralType_IsQuadrilateral) {
                    //是四边形
                    isResetCornerPoints = YES;
                    [_pointsArray replaceObjectsInRange:NSMakeRange(0, 4) withObjectsFromArray:tempPoints];
                    break;
                }
            }
            //重绘边框
            if (isResetCornerPoints) {
                
            }
        }
            break;
            
        default:
            break;
    }
    
    //检测是否为内四边形
    _isInQuadrilateral = [self justifyIsInQuadrilateralWithIndex:_currentMovingPointIndex];
    //四个边角点 A B C D，重新初始化中点
    [self initCenterPointBetweenTwo];
    if (self.delegate) {
        if ([self.delegate respondsToSelector:@selector(redrawRect)]) {
            [self.delegate redrawRect];
        }
    }
}

//四个顶点的全排列
-(NSMutableArray*)allRangeOfFourCornerPoints:(NSMutableArray*)cornerPoints{
    
    //四个顶点
    //一个数组的全排列
    NSMutableArray *allRanges = [NSMutableArray array];
    [self allRangeOfArray:cornerPoints locIndex:0 length:3 allRanges:allRanges];
    
    return allRanges;
}
//递归算法 求一个数组的全排列
-(void)swapArray:(NSMutableArray*)array
          index1:(NSInteger)index1
          index2:(NSInteger)index2
{
    [array exchangeObjectAtIndex:index1 withObjectAtIndex:index2];
}
-(void)allRangeOfArray:(NSMutableArray*)array
              locIndex:(NSInteger)loc
                length:(NSInteger)len
             allRanges:(NSMutableArray*)allRanges
{
    NSInteger i;
    if(loc >len) {
        //数组的一个排列方式
        NSLog(@"array=%@",array);
        [allRanges addObject:[NSMutableArray arrayWithArray:array]];
    }
    else
    {
        for(i = loc; i <=len;i++)
        {
            [self swapArray:array index1:loc index2:i];
            [self allRangeOfArray:array locIndex:loc+1 length:len allRanges:allRanges];
            [self swapArray:array index1:loc index2:i];
        }
    }
}

//四边形内角和计算
-(QuadrilateralType)countInsideAngleSummerWithCornerPoints:(NSArray*)cornerPoints {
    /* 边框圆 A B C D E F G H
     A--E--B
     |     |
     H     F
     |     |
     D--G--C
     */
    //A
    NSArray *tempA = cornerPoints[0];
    //B
    NSArray *tempB = cornerPoints[1];
    //C
    NSArray *tempC = cornerPoints[2];
    //D
    NSArray *tempD = cornerPoints[3];
    
    //向量AB AD 夹角A
    NSArray *ab_vector = [self caculatorTowVectorsWithPoint1:tempA point2:tempB];
    NSArray *ad_vector = [self caculatorTowVectorsWithPoint1:tempA point2:tempD];
    CGFloat angleA_value = [self caculateTowVectorAngleVector1:ab_vector vector2:ad_vector];
    
    //向量BA BC 夹角B
    NSArray *ba_vector = [self caculatorTowVectorsWithPoint1:tempB point2:tempA];
    NSArray *bc_vector = [self caculatorTowVectorsWithPoint1:tempB point2:tempC];
    CGFloat angleB_value = [self caculateTowVectorAngleVector1:ba_vector vector2:bc_vector];
    
    //向量CA CD 夹角C
    NSArray *cb_vector = [self caculatorTowVectorsWithPoint1:tempC point2:tempB];
    NSArray *cd_vector = [self caculatorTowVectorsWithPoint1:tempC point2:tempD];
    CGFloat angleC_value = [self caculateTowVectorAngleVector1:cb_vector vector2:cd_vector];
    
    //向量DC DB 夹角D
    NSArray *dc_vector = [self caculatorTowVectorsWithPoint1:tempD point2:tempC];
    NSArray *da_vector = [self caculatorTowVectorsWithPoint1:tempD point2:tempA];
    CGFloat angleD_value = [self caculateTowVectorAngleVector1:dc_vector vector2:da_vector];
    
    QuadrilateralType type = 0;
    //如果内角和 angleA+angleB+angleC+angleD=360:四边形-0; >360:内四边形-1; <360:有交叉-2;
    CGFloat summer = (angleA_value+angleB_value+angleC_value+angleD_value)-360;
    //允许误差在5度
    if (fabs(summer)<=5) {
        type = QuadrilateralType_IsQuadrilateral;
    }else if (summer>0) {
        type = QuadrilateralType_InsideQuadrilateral;
    }else if (summer<0) {
        type = QuadrilateralType_NotQuadrilateral;
    }
    return type;
}
//两点之间求向量
-(NSArray*)caculatorTowVectorsWithPoint1:(NSArray*)p1 point2:(NSArray*)p2{
    
    CGFloat x = [p1[0] floatValue]-[p2[0] floatValue];
    CGFloat y = [p1[1] floatValue]-[p2[1] floatValue];
    return @[[NSNumber numberWithFloat:x], [NSNumber numberWithFloat:y]];
}
//计算两个向量之间的夹角
-(CGFloat)caculateTowVectorAngleVector1:(NSArray*)vector1 vector2:(NSArray*)vector2 {
    
    //计算两个向量a、b之间的内积
    //cos angle = 向量a、b的内积 / (向量a的模*向量b的模)
    //内积
    CGFloat abInS = [vector1[0] floatValue]*[vector2[0] floatValue]
    +[vector1[1] floatValue]*[vector2[1] floatValue];
    //向量的模
    CGFloat aM = sqrtf(pow([vector1[0] floatValue], 2)+pow([vector1[1] floatValue], 2));
    CGFloat bM = sqrtf(pow([vector2[0] floatValue], 2)+pow([vector2[1] floatValue], 2));
    
    //两向量夹角余弦值
    CGFloat cos_AngleValue = abInS/(aM*bM);
    //弧度
    CGFloat hudu = acos(cos_AngleValue);
    //弧度转换成角度
    CGFloat angle=hudu*180/3.1415;
    //取绝对值
    angle=fabs(angle);
    
    return angle;
}




#pragma mark 四边形判断准则1 - 根据x/y轴坐标
//检测是否为内四边形
-(BOOL)justifyIsInQuadrilateralWithIndex:(NSInteger)index
{
    BOOL isInQuadrilateralTemp = NO;
    //index
    NSInteger a=0, b=0,c=0,d=0;
    a = index%4;
    //对角点
    c = (index+2)%4;
    //index旁边点
    b = (index+1)%4;
    d = (index+3)%4;
    //ac
    CGPoint tempA = [self getCGPointWithNumbersArray:[_pointsArray objectAtIndex:a]];
    CGPoint tempC = [self getCGPointWithNumbersArray:[_pointsArray objectAtIndex:c]];
    //bd中间点
    CGPoint tempB = [self getCGPointWithNumbersArray:[_pointsArray objectAtIndex:b]];
    CGPoint tempD = [self getCGPointWithNumbersArray:[_pointsArray objectAtIndex:d]];
    
    //判断A、C是否在直线BD同一侧
    //直线BD
    TJLineModel *lineBD = [TJLineModel newLineModelWithPoint1:tempB point2:tempD];
    //y>kx+b直线斜截式判断
    if (tempB.x==tempD.x) {
        //垂直于x轴的直线
        if ((tempA.x<tempB.x&&tempC.x<tempB.x) || (tempA.x>tempB.x&&tempC.x>tempB.x)) {
            isInQuadrilateralTemp = YES;
        }
    }else if (tempB.y==tempD.y) {
        //垂直于y轴的直线
        if ((tempA.y<tempB.y&&tempC.y<tempB.y) || (tempA.y>tempB.y&&tempC.y>tempB.y)) {
            isInQuadrilateralTemp = YES;
        }
    }else{
        //直线斜率存在
        CGFloat ya = lineBD.lineSlope*tempA.x+lineBD.lineValueB;
        CGFloat yc = lineBD.lineSlope*tempC.x+lineBD.lineValueB;
        
        if((tempA.y>ya&&tempC.y>yc) || (tempA.y<ya&&tempC.y<yc))
        {
            isInQuadrilateralTemp = YES;
        }
    }
    
    return isInQuadrilateralTemp;
}

@end
