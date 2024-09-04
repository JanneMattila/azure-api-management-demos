using SOAPService.Models;
using System.Collections.Generic;
using System.Linq;
using System.Web.Services;

namespace SOAPService.Services
{
    [WebService(Namespace = "https://products.jannemattila.com/")]
    [WebServiceBinding(ConformsTo = WsiProfiles.BasicProfile1_1)]
    [System.ComponentModel.ToolboxItem(false)]
    public class ProductsService : System.Web.Services.WebService
    {
        static private List<Product> _products = new List<Product>
        {
            new Product { Id = 1, Name = "Product 1", Description = "Description 1", Price = 100 },
            new Product { Id = 2, Name = "Product 2", Description = "Description 2", Price = 200 },
            new Product { Id = 3, Name = "Product 3", Description = "Description 3", Price = 300 },
            new Product { Id = 4, Name = "Product 4", Description = "Description 4", Price = 400 },
            new Product { Id = 5, Name = "Product 5", Description = "Description 5", Price = 500 }
        };

        [WebMethod]
        public List<Product> GetProducts()
        {
            // Return a list of products
            return _products;
        }

        [WebMethod]
        public Product GetProduct(int id)
        {
            // Find a product by id
            return _products.FirstOrDefault(p => p.Id == id);
        }

        [WebMethod]
        public void AddProduct(Product product)
        {
            // Add a new product
            _products.Add(product);
        }

        [WebMethod]
        public void UpdateProduct(Product product)
        {
            // Find a product by id
            var existingProduct = _products.FirstOrDefault(p => p.Id == product.Id);

            // Update the product
            if (existingProduct != null)
            {
                existingProduct.Name = product.Name;
                existingProduct.Description = product.Description;
                existingProduct.Price = product.Price;
            }
        }

        [WebMethod]
        public void DeleteProduct(int id)
        {
            // Find a product by id
            var product = _products.FirstOrDefault(p => p.Id == id);

            // Remove the product
            if (product != null)
            {
                _products.Remove(product);
            }
        }

        [WebMethod]
        public void ClearProducts()
        {
            // Clear all products
            _products.Clear();
        }
    }
}
