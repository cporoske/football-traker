# 足球跟踪
基于Matlab的简单足球跟踪器

## 运行截图
1. result1.gif ([http://pw9l1zd1z.bkt.clouddn.com/result1.gif](http://pw9l1zd1z.bkt.clouddn.com/result1.gif "image url"))  
![result1](https://raw.githubusercontent.com/cporoske/football-traker/master/result1.gif "image not loaded")

2. result3.gif([http://pw9l1zd1z.bkt.clouddn.com/result3.gif](http://pw9l1zd1z.bkt.clouddn.com/result3.gif "image url"))  
![result2](https://raw.githubusercontent.com/cporoske/football-traker/master/result3.gif  "image not loaded")

3. 丢失.gif([http://pw9l1zd1z.bkt.clouddn.com/%E4%B8%A2%E5%A4%B1.gif](http://pw9l1zd1z.bkt.clouddn.com/%E4%B8%A2%E5%A4%B1.gif  "image url"))  
![result3](https://raw.githubusercontent.com/cporoske/football-traker/master/%E4%B8%A2%E5%A4%B1.gif  "image not loaded")

## 算法原理
1. 首先将图像从RGB转化位HSL，然后对待跟踪的视频图像序列进行统计求平均值，提取足球草地主颜色
2. 依据上一步得到的足球草地主色，通过定义颜色空间距离模型，可以对图像进行二值化，以将草地和足球以及球员分离
3. 对得到的二值化图像做形态学处理，弥补上一步分割产生的断口；此外，可以让足球像素点增多，以便之后提取
4. 求取连通域，分别对每一个连通域计算该连通域所包含的像素点数量，该算法运行的**假设**在于足球是像素点较少的连通域
5. 求取足球的中心点，并和上一帧坐标比对，是否超出界限；如果超出，则按照上一帧的速度继续运行，否则更新足球坐标

## 总结
事实上，算法原理比较简单，因此性能并不是很好，仅作学习参考之用。