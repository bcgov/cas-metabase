package main

import (
	"io/ioutil"
	"log"
	"net/http"
	"fmt"
	"crypto/tls"
	"encoding/json"
	"bytes"
	"time"
	"os"
)

// Function logs in and returns a session id for use in subsequent API calls
func getSession(url string, client http.Client) string {
	api_endpoint := fmt.Sprintf("%s/api/session", url)
	user := os.Args[2]
	pass := os.Args[3]

	// Encode the body data
	postBody, _ := json.Marshal(map[string]string{
		"username":  user,
		"password": pass,
	})
	requestBody := bytes.NewBuffer(postBody)

	// Create http request and set headers
	req, err := http.NewRequest("POST", api_endpoint, requestBody)
	if err != nil {
		 log.Fatalln(err)
	}
	req.Header.Set("Content-Type", "application/json")

	// Send http request
	res, err := client.Do(req)
	if err != nil {
		log.Fatalln(err)
 	}

	// Do not close response until the function is done
	defer res.Body.Close()

	// Read the response body
	body, err := ioutil.ReadAll(res.Body)
	if err != nil {
		 log.Fatalln(err)
	}

	// Parse the response & return the session id
	var data map[string]interface{}

	if err := json.Unmarshal(body, &data); err != nil {
		panic(err)
	}
	id := data["id"].(string)
	return id
}

// Function gets all questions from metabase & returns an array containing all the question ids
func getAllQuestions(url string, session_id string, client http.Client) []int {
	var all_questions []int
	api_endpoint := fmt.Sprintf("%s/api/card", url)

	// Create http request & set headers
	req, err := http.NewRequest("GET", api_endpoint, nil)
	if err != nil {
		log.Fatalln(err)
	}
	req.Header.Set("Cache-Control", "no-cache")
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Accept", "application/json")
	req.Header.Set("X-Metabase-Session", session_id)

	// Send http request
	res, err := client.Do(req)
	if err != nil {
		log.Fatalln(err)
	}

	// Do not close response until the function is done
	defer res.Body.Close()

	// Read the response body
	body, err := ioutil.ReadAll(res.Body)
	if err != nil {
		 log.Fatalln(err)
	}

	// Parse the response and return an array of question ids
	var objs interface{}
	json.Unmarshal([]byte(body), &objs)

	objArr, ok := objs.([]interface{})
	if !ok {
			log.Fatal("expected an array of objects")
	}

	for _, obj := range objArr {
			obj, ok := obj.(map[string]interface{})
			if !ok {
					log.Fatalf("expected type map[string]interface{}, got")
			}
			all_questions = append(all_questions, int(obj["id"].(float64)))
	}
	return all_questions
}

// Function determines if a metabase question is broken when passed a question id. Returns boolean.
func questionIsBroken(url string, session_id string, id int, client http.Client) bool {
	api_endpoint := fmt.Sprintf("%s/api/card/%d/query", url, id)

	// Create http request & set headers
	req, err := http.NewRequest("POST", api_endpoint, nil)
	if err != nil {
		log.Fatalln(err)
	}
	req.Header.Set("Cache-Control", "no-cache")
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Accept", "application/json")
	req.Header.Set("X-Metabase-Session", session_id)

	// Send http request
	res, err := client.Do(req)
	log.Println(res)
	if err != nil {
		// Return broken=true if query fails (ie: timeout)
		return true
	}

	// Do not close response until the function is done
	defer res.Body.Close()

	// Read the response body
	body, err := ioutil.ReadAll(res.Body)
	if err != nil {
		 log.Fatalln(err)
	}

	// Parse the response & return true/false depending on if the question is broken
	var data map[string]interface{}
	if err := json.Unmarshal(body, &data); err != nil {
		log.Fatalln(err)
	}
	error := data["error"]
	if error == nil {
		return false
	}
	return true
}

// Function gets data relating to a broken question and returns a concatenated string of that data
func getQuestionData(url string, session_id string, question_id int, client http.Client) string {
	api_endpoint := fmt.Sprintf("%s/api/card/%d", url, question_id)

	// Create http request & set headers
	req, err := http.NewRequest("GET", api_endpoint, nil)
	if err != nil {
		log.Fatalln(err)
	}
	req.Header.Set("Cache-Control", "no-cache")
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Accept", "application/json")
	req.Header.Set("X-Metabase-Session", session_id)

	// Send http request
	res, err := client.Do(req)
	if err != nil {
		log.Fatalln(err)
	}

	// Do not close response until the function is done
	defer res.Body.Close()

	// Read the response body
	body, err := ioutil.ReadAll(res.Body)
	if err != nil {
		 log.Fatalln(err)
	}

	// Parse the response & return a concatenated string of data relating to the question {id, creator, updated_at}
	var data map[string]interface{}
	if err := json.Unmarshal(body, &data); err != nil {
		log.Fatalln(err)
	}

	updated_at := (data["updated_at"])
	creator := data["creator"].(map[string]interface{})["email"]

	result := fmt.Sprintf("{%d, %s, %s}", question_id, creator, updated_at)

	return result
}

func main() {
	if len(os.Args) !=4 || os.Args[1] == "-h" {
		fmt.Println("Usage: broken_questions <Metabase URL> <Username> <Password>")
		os.Exit(1)
	}

	http.DefaultTransport.(*http.Transport).TLSClientConfig = &tls.Config{InsecureSkipVerify: true}
	url := os.Args[1]
	var broken_data []string

	// Create http client
	client := http.Client{
		Timeout: time.Duration(5 * time.Second),
	}

	// Get session id
	session_id := getSession(url, client)

	// Get array of question ids
	question_array := getAllQuestions(url, session_id, client)

	// For all ids in the question array, check if each question is broken.
	for _, question_id := range question_array {
		if questionIsBroken(url, session_id, question_id, client) {
    	broken_data = append(broken_data, getQuestionData(url, session_id, question_id, client))
		}
	}

	// Print results
	if len(broken_data) == 0 {
		fmt.Println("No broken questions were found")
		os.Exit(0)
	}
	if len(broken_data) > 0 {
		fmt.Println("Broken questions were detected {id, author, updated_at}: ")
		fmt.Println(broken_data)
		os.Exit(0)
	}

}


