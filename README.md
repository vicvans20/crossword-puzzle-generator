# Ruby Simple Crossword Generator
Ruby Crossword Puzzle Generator. Based on <a href="http://bryanhelmig.com/python-crossword-puzzle-generator/"> Python Crossword Puzzle Generator.</a>

# Basic Usage
### Load the code:
```
:01 > load 'crossword.rb'
 ```
### Simple Puzzle Generation
```
:02 > word_list = [['pain','breakfast commonly!'], ['papillon','flying over the grass'], ['femme','!man'], ['parle','communication action']]
:03 > c = Crossword.new(8,6,'*', 5000, word_list)
:04 > c.compute_crossword(3)
```
### Puzzle Display
Crossword:
```
:05 > puts c.solution
p a p i l l o n 
a * a * * * * * 
i * r * * * * * 
n * l * * * * * 
* f e m m e * * 
* * * * * * * *
```
Crossword legend and coordinates:
```
:06 > puts c.display
1   2           
  *   * * * * * 
  *   * * * * * 
  *   * * * * * 
* 3         * * 
* * * * * * * *

:07 > puts c.legend
1. (1, 1) across: flying over the grass
1. (1, 1) down: breakfast commonly!
2. (3, 1) down: communication action
3. (2, 5) across: !man
```
Word find:
```
:08 > puts c.word_find
p a p i l l o n 
a u a q g u o i 
i n r j i h t n 
n x l a n g e d 
v f e m m e f n 
b t p i y z f t 
```
