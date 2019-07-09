# General formatting
set terminal png size 400,300 enhanced font "Helvetica,20"
set border linewidth 1.5
set style line 1 linecolor rgb '#dd181f' linetype 1 linewidth 1

# Function to raise a variable to itself
to_self(x) = x**x

plot to_self(x) title 'to-self(x)' with lines linestyle 1
