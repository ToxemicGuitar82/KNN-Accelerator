# Architecture:

### KNN_TOP:
The top level module of the accelerator. Implements distance calculations, sorter, and classifier modules

### DIST_TOP:
Top level module for the distance calculations. Implements 3 distance calculations: Squared Euclidean, Manhattan Distance, and Euclidean.

Squared Euclidean is implemented using dist_sq_euc.v
Manhattan is implemented using dist_man.v
Euclidean is implemented using dist_sq_euc.v and sqrt.v

### SORTER:
Sorting module that implements selection sort. 

### CLASSIFIER:
Final module that classifies the location of the unknown data point using the classes of the K-Nearest Neighbors.


# Top Level I/Os:
- WIDTH represents number of bits for data, TAG represents number of bits for the class, and MEM_SIZE represents total number of data points that can be streamed to the accelerator.
- Input data locations are TAG + WIDTH bits wide.
- x1 and y1 represent the location of he unlabeled data point.
- x2 and y2 represent the locations of the labeled data points.
- sel_i represents the type of distance calculation to be used where, 0 is euclidean distance, 1 is squared euclidean distance, and 2 is manhattan distance.
- num_i represents the total number of inputs that will be streamed to the system
- K_i represents the K value for the K-nearest neighbors.
- valid_i, yumi_i, valid_o, and ready_o represent flow control signals to stream input data.
- dist_o represents the calculated distance.
- dist_v_o represents if the calculated distance is valid or not.
- rem_o represents the remainder associated with distance calculation (only relevant when using euclidean distance calculation).
- sorted_data_o represents the sorted output values being streamed from the sorter.
- sorted_v_data_o represents that the output values being streamed from the sorter are valid or not.
- class_o represents the predicted class of the unlabeled data point.
- done_o represents that the system is done processing.

