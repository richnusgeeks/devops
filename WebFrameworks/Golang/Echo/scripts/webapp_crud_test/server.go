package main

import (
	"database/sql"
	"fmt"
	"github.com/labstack/echo/v4"
	"github.com/labstack/echo/v4/middleware"
	_ "github.com/lib/pq"
	"net/http"
	"os"
)

type Employee struct {
	Name   string `json: "name"`
	Salary string `json: "salary"`
	Age    string `json: "age"`
}

type Employees struct {
	Employees []Employee `json:"employees"`
}

func checkError(err error) {
	if err != nil {
		panic(err)
	}
}

func getEnv(key, fallback string) string {
	if value, ok := os.LookupEnv(key); ok {
		return value
	}
	return fallback
}

func main() {
	host := getEnv("DB_HOST", "postgres")
	port := getEnv("DB_PORT", "5432")
	user := getEnv("DB_USER", "postgres")
	pswd := getEnv("DB_PSWD", "postgres")
	dbnm := getEnv("DB_NAME", "wacrudtest")

	psqlconn := fmt.Sprintf("host=%s port=%s user=%s password=%s dbname=%s sslmode=disable", host, port, user, pswd, dbnm)

	db, err := sql.Open("postgres", psqlconn)
	checkError(err)

	err = db.Ping()
	defer db.Close()

	// setup Echo
	e := echo.New()
	e.Use(middleware.Logger())
	e.Use(middleware.Recover())

	// setup Routes
	e.POST("/employees", func(c echo.Context) error {
		u := new(Employee)
		err := c.Bind(u)
		checkError(err)

		sqlStatement := "INSERT INTO employees (name, salary, age) VALUES ($1, $2, $3)"
		res, err := db.Query(sqlStatement, u.Name, u.Salary, u.Age)
		checkError(err)
		fmt.Println(res)
		return c.JSON(http.StatusCreated, u)
	})

	e.GET("/employees/:id", func(c echo.Context) error {
		id := c.Param("id")
		u := new(Employee)
		err := c.Bind(u)
		checkError(err)

		sqlStatement := "SELECT name, salary, age FROM employees WHERE id=$1"
		res, err := db.Query(sqlStatement, id)
		checkError(err)
		fmt.Println(res)
		defer res.Close()

		result := Employee{}
		for res.Next() {
			err := res.Scan(&result.Name, &result.Salary, &result.Age)
			checkError(err)
		}
		return c.JSON(http.StatusOK, result)
	})

	e.GET("/employees", func(c echo.Context) error {
		sqlStatement := "SELECT name, salary, age FROM employees order by id"
		rows, err := db.Query(sqlStatement)
		checkError(err)
		defer rows.Close()

		result := Employees{}
		for rows.Next() {
			employee := Employee{}
			err := rows.Scan(&employee.Name, &employee.Salary, &employee.Age)
			checkError(err)
			result.Employees = append(result.Employees, employee)
		}
		return c.JSON(http.StatusOK, result)
	})

	e.PUT("/employees/:id", func(c echo.Context) error {
		id := c.Param("id")
		u := new(Employee)
		err := c.Bind(u)
		checkError(err)

		sqlStatement := "UPDATE employees SET name=$1,salary=$2,age=$3 WHERE id=$4"
		res, err := db.Query(sqlStatement, u.Name, u.Salary, u.Age, id)
		checkError(err)
		fmt.Println(res)
		return c.JSON(http.StatusOK, id)
	})

	e.DELETE("/employees/:id", func(c echo.Context) error {
		id := c.Param("id")
		sqlStatement := "DELETE FROM employees WHERE id = $1"
		db.Query(sqlStatement, id)
		return c.NoContent(http.StatusNoContent)
	})

	// start Server
	hstprt := getEnv("HOST_PORT", ":8080")
	e.Logger.Fatal(e.Start(hstprt))
}
