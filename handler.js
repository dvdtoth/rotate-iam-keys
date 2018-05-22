// A simple lambda function to revoke IAM roles of groups periodically
// By @dvdtoth

'use strict';

const aws = require('aws-sdk');
const iam = new aws.IAM();

// Delete an access key by id
function deleteAccessKey(id, username) {

  let params = {
    AccessKeyId: id,
    UserName: username
  };

  return iam.deleteAccessKey(params).promise()
    .catch(err => {
      // Key might have been deleted already if user is in multiple groups
      if (err.code == "NoSuchEntity") {
        Promise.resolve();
      }
      else {
        throw err;
      }
    })
}

// Delete access keys of username
function deleteByUser(username) {

  let params = {
    UserName: username
  };

  return iam.listAccessKeys(params).promise()
    .then(data => {
      return Promise.all(data.AccessKeyMetadata.map(metadata => {
        console.log('Deleting access key ' + metadata.AccessKeyId + ' for user ' + username);
        return deleteAccessKey(metadata.AccessKeyId, username);
      }))
    })
}

// Delete all keys for users in group
function deleteKeysInGroup(group) {

  let params = {
    GroupName: group,
  };

  return iam.getGroup(params).promise()
    .then(group_data => {
      let group_users = group_data.Users;
      return Promise.all(group_data.Users.map(user => {
        return deleteByUser(user.UserName);
      }))
    })
}

// AWS Lambda handler
module.exports.revoke = (event, context, callback) => {

  // clear whitespaces, split by comma
  let groups = process.env.GROUPS.replace(/\s/g, '').split(',');

  // Delete access keys asynchronously from groups
  Promise.all(groups.map(deleteKeysInGroup))
    .then(data => {
      callback(null, {
        message: 'Keys successfully deleted',
        event
      });
    })

    .catch(err => {
      callback(err, {
        message: 'Failed to delete keys',
        event
      });
    })
}