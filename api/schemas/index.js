module.exports = {
    getTransfersSchema: require('./get_transfers'),
    getAbiSnapshotSchema: require('./get_abi_snapshot'),
    getKeyAccountsSchema: require('./get_key_accounts'),
    getKeyAccountsV1Schema: require('./get_key_accounts_v1'),
    getActionsSchema: require('./get_actions'),
    getActionsV1Schema: require('./get_actions_v1'),
    getTransactedAccountsSchema: require('./get_transacted_accounts'),
    getTransactionSchema: require('./get_transaction'),
    getTransactionV1Schema: require('./get_transaction_v1'),
    getCreatorSchema: require('./get_creator'),
    getControlledAccountsV1Schema: require('./get_controlled_accounts_v1'),
    getTokensSchema: require('./get_tokens'),
    getDeltasSchema: require('./get_deltas'),
    getCreatedAccountsSchema: require('./get_created_accounts'),
    getVotersSchema: require('./get_voters')
};
