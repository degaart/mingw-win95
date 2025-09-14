#include <iostream>
#include <stdexcept>

int main()
{
    try
    {
        throw std::runtime_error("This is an exception");
    }
    catch(const std::exception& ex)
    {
        std::cout << "Exception: " << ex.what() << "\n";
    }
    return 0;
}

