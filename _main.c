//
//  main.c
//  AsciiGenerator
//
//  Created by Amy Dyer on 6/4/12.
//  Copyright (c) 2012 Amy Dyer. Do whatever you like with this.
//

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <assert.h>
#import "letter.h"
#import "bitmap.h"

static void calculateGrid(unsigned char * bmpData, int gridCols, int gridRows, int width, int height, node_t * root)
{
    int rowSize = (BITS_PER_PIXEL * width)/32 * 4;
    
    int gridHeight = height/gridRows;
    int gridWidth = width/gridCols;
    
    for (int row=0; row<gridHeight; row++) {
        for (int col=0; col<gridWidth; col++) {
            float sum = 0;
            for (int pxRow=0; pxRow<gridRows; pxRow++) {
                for (int pxCol=0; pxCol<gridCols; pxCol++) {
                    float val = darkness(locatePixel(bmpData, rowSize, row*gridRows+pxRow, col*gridCols+pxCol));
                    sum+=val;
                }
            }
            sum = sum/(gridCols * gridRows);
            char * letter = findLetter(root, sum);
            printf("%s", letter);
        }
        printf("\n");
    }

}

static char * readFileData(const char * definitionsFilePath, size_t * length)
{
    size_t fileSize = 1024;
    size_t buffSize = 256;
    
    FILE * file = fopen(definitionsFilePath, "r");
    
    if (file == NULL) {
        printf("Definitions file \"%s\" could not be opened.", definitionsFilePath);
        exit(EXIT_FAILURE);
    }
    
    char * fileData = malloc(sizeof(char) * fileSize);
    char * buff = malloc(sizeof(char) * buffSize);
    
    size_t len = 0;
    size_t bytesRead = 0;
    
    while ((len = fread(buff, sizeof(char), buffSize, file))) {
        size_t newSize = bytesRead+len;
       
        if (newSize > fileSize) {
            fileSize = newSize;
            fileData = realloc(fileData, newSize);
        }
        
        memcpy(fileData+bytesRead, buff, len);
        bytesRead=newSize;
    }
    
    free(buff);
    
    *length = bytesRead;
    return fileData;
}

static node_t * createTreeFromFile(const char * definitionsFilePath)
{
    size_t length = 0;
    char * data = readFileData(definitionsFilePath, &length);
    char * buff = malloc(sizeof(char) * 32);
    
    int bytesRead = 0;
    
    float darkness = 0;
    char * letter = 0;
    
    for (int i=0; i<length; i++) {
        char c = data[i];
        
        if (bytesRead > 32) {
            printf("Definitions file contains value that is longer than 32 bytes");
            exit(EXIT_FAILURE);
        }
        
        memcpy(buff+bytesRead, &c, 1);
        
        bytesRead++;
        
        
        if (c == ':' || c == '\n' || c == ';') {
            
            char * str = malloc(bytesRead * sizeof(char));
            memset(str, 0, bytesRead);
            memcpy(str, buff, bytesRead-1);
            
            bytesRead = 0;
            
            if (c == ':') {
                //First section - a letter
                letter = malloc(sizeof(str));
                strcpy(letter, str);
            } else {
                //Second section - a float
                darkness = atof(str);
                
                if (treeRoot == NULL) {
                    treeRoot = newNode(letter, darkness);
                } else {
                    insertLetter(treeRoot, letter, darkness);
                    free(letter);
                }
            }
            
            free(str);
            
        }
    }
    
    free(buff);
    free(data);
    
    return treeRoot;
}

int main (int argc, const char * argv[])
{    
    if (argc < 3) {
        printf("Usage: asciigenerator input.bmp definition.txt [grid size]\n");
        exit(EXIT_SUCCESS);
    }
    
    const char * inputFile = argv[1];
    const char * definitionsFile = argv[2];
        
    treeRoot = createTreeFromFile(definitionsFile);
       
    int width = 0;
    int height = 0;
    int rowSize = 0;
     
    unsigned char * bmpData = createBitmapData(inputFile, &width, &height, &rowSize);
    int gridCols = 1;
    int gridRows = 1;
    if (argc == 5) {
        gridCols = atoi(argv[3]);
        gridRows = atoi(argv[4]);
    }
   
    calculateGrid(bmpData, gridCols, gridRows, width, height, treeRoot);
    
    free(bmpData);
    destroyTree(treeRoot);
    
    return 0;
}

