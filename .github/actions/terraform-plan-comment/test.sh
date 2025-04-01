# Check if plan JSON exists
if [ ! -f "$PLAN_JSON_PATH" ]; then
  echo "Plan JSON file not found: $PLAN_JSON_PATH"
  exit 1
fi

# Generate the comment using Node.js
node -e '
  const fs = require("fs");
  const { execSync } = require("child_process");
  
  try {
    // Read the plan JSON
    const planOutput = fs.readFileSync(process.env.PLAN_JSON_PATH, "utf8");
    const plan = JSON.parse(planOutput);
    
    // Format plan resource changes for comment
    let planSummary = `### ${process.env.TITLE}\n\n`;
    planSummary += "| Resource | Action |\n";
    planSummary += "|----------|--------|\n";
    
    if (plan.resource_changes) {
      // Filter out no-op changes
      const changes = plan.resource_changes.filter(change => 
        !change.change.actions.includes("no-op") &&
        change.change.actions.length > 0 &&
        change.change.actions[0] !== "no-op"
      );
      
      if (changes.length > 0) {
        changes.forEach(change => {
          planSummary += `| \`${change.address}\` | ${change.change.actions.join(", ")} |\n`;
        });
      } else {
        planSummary += "| No significant changes | - |\n";
      }
    } else {
      planSummary += "| No changes | - |\n";
    }
    
    // Add the full plan output in a collapsible section
    planSummary += "\n<details><summary>View Full Plan Output</summary>\n\n```hcl\n";
    planSummary += execSync(`terraform show ${process.env.PLAN_PATH}`).toString();
    planSummary += "\n```\n</details>\n";
    
    // Create GitHub API request body
    const body = JSON.stringify({
      body: planSummary
    });
    
    // Post the comment to GitHub API
    const [owner, repo] = process.env.REPOSITORY.split("/");
    const commentUrl = `https://api.github.com/repos/${owner}/${repo}/issues/${process.env.PR_NUMBER}/comments`;
    const result = execSync(`curl -s -X POST ${commentUrl} -H "Authorization: token ${process.env.GITHUB_TOKEN}" -H "Content-Type: application/json" -d ''${body.replace(/''/g, "\\''")}''`);
    
    console.log("Comment posted successfully!");
  } catch (error) {
    console.error("Error creating PR comment:", error);
    process.exit(1);
  }
'